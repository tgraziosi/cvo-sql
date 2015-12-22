SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_edi_process_all]
	@cust_code 	varchar(10), 
	@cust_po	varchar(20),
	@err_msg	varchar(255) OUTPUT

AS

DECLARE @ship_to 	varchar(10),
	@gross_wt  	varchar(15),
	@asn		int,
	@ret		int,
	@carton_no	int  

TRUNCATE TABLE #edi_asn_processed
TRUNCATE TABLE #int_list_in

IF @cust_po = '' SELECT @cust_po = NULL

DECLARE edi_ship_to_cur CURSOR FAST_FORWARD READ_ONLY FOR
	SELECT ship_to FROM #tdc_ship_to_input
OPEN edi_ship_to_cur
FETCH NEXT FROM edi_ship_to_cur INTO @ship_to
WHILE @@FETCH_STATUS = 0
BEGIN
	------------------------------------------------------------------------------------------------------
	-- Get the next ASN number
	------------------------------------------------------------------------------------------------------
 	EXEC @asn = tdc_get_serialno
	
	INSERT INTO #edi_asn_processed (asn) 
	VALUES(@asn)

	IF NOT EXISTS(SELECT TOP 1 * FROM tdc_edi_processed_asn (NOLOCK)   
	       	       WHERE asn = @asn)
	BEGIN                                               
     		INSERT INTO tdc_edi_processed_asn (asn, cust_code, cust_po, ship_to)
     		VALUES(@asn, @cust_code, @cust_po, @ship_to)
	END     

	DECLARE edi_carton_cur CURSOR FAST_FORWARD READ_ONLY FOR
	   SELECT DISTINCT a.carton_no
	               FROM tdc_stage_carton a (NOLOCK), 
	                    tdc_carton_tx    b (NOLOCK)   
	              WHERE a.tdc_ship_flag = 'Y'  
	                AND b.cust_code = @cust_code
			AND b.status = 'X'
	                AND b.cust_po NOT LIKE 'SAMPLE%'
	                AND b.carton_no = a.carton_no  
	                AND a.carton_no NOT IN (SELECT DISTINCT child_serial_no
	                              From tdc_dist_group (NOLOCK)
	                             Where method = '01'
	                               AND type = 'E1')
			AND b.ship_to_no = @ship_to
			AND (ISNULL(@cust_po, '') = '' OR b.cust_po = @cust_po)
	OPEN edi_carton_cur
	FETCH NEXT FROM edi_carton_cur INTO @carton_no
	WHILE @@FETCH_STATUS = 0
	BEGIN
		------------------------------------------------------------------------------------------------------
		-- Master Pack
		------------------------------------------------------------------------------------------------------
		IF EXISTS (SELECT * FROM tdc_dist_group (NOLOCK)
				 WHERE parent_serial_no = @carton_no
				   AND method = '01'
				   AND type = 'S1'
				   AND status = 'O')
		BEGIN
			EXEC @ret = tdc_asn_add_mp_sp @asn, @carton_no, '01', @err_msg OUTPUT						
			IF @ret != 0 
			BEGIN
				CLOSE edi_ship_to_cur
				DEALLOCATE edi_ship_to_cur
				CLOSE edi_carton_cur
				DEALLOCATE edi_carton_cur								
				RETURN -1
			END
		END
		ELSE
		------------------------------------------------------------------------------------------------------
		-- Not Master Pack
		------------------------------------------------------------------------------------------------------	
		BEGIN
			EXEC @ret = tdc_asn_add_carton_sp @asn, @carton_no, '01', @err_msg OUTPUT
			IF @ret != 0 
			BEGIN
				CLOSE edi_ship_to_cur
				DEALLOCATE edi_ship_to_cur
				CLOSE edi_carton_cur
				DEALLOCATE edi_carton_cur		
				RETURN -2
			END
	 	END	
		
		FETCH NEXT FROM edi_carton_cur INTO @carton_no
	END	
	CLOSE edi_carton_cur
	DEALLOCATE edi_carton_cur
	FETCH NEXT FROM edi_ship_to_cur INTO @ship_to
END
CLOSE edi_ship_to_cur
DEALLOCATE edi_ship_to_cur

DECLARE edi_asn_cur CURSOR FAST_FORWARD READ_ONLY FOR 
	SELECT asn FROM #edi_asn_processed
OPEN edi_asn_cur
FETCH NEXT FROM edi_asn_cur INTO @asn
WHILE @@FETCH_STATUS = 0
BEGIN
	--close the asn
	IF EXISTS (SELECT TOP 1 * FROM tdc_dist_group (NOLOCK) 
		WHERE parent_serial_no = @asn
		  AND method = '01' 
		  AND type = 'E1' 
		  AND [function] = 'S' AND status <> 'C')
	BEGIN
		EXEC @ret = tdc_asn_close_sp @asn, '01', @err_msg OUTPUT
		IF @ret != 0 
		BEGIN
			CLOSE edi_asn_cur
			DEALLOCATE edi_asn_cur
			RETURN -3
		END
	END
	--INSERT asn INFO
	INSERT INTO #int_list_in (serial_no, gross_wt) 
		SELECT @asn, LTRIM(CONVERT(VARCHAR(15), STR(SUM(weight)))) FROM tdc_carton_tx (NOLOCK)
					WHERE carton_no IN (SELECT child_serial_no FROM tdc_dist_group (NOLOCK) WHERE parent_serial_no = @asn)


	FETCH NEXT FROM edi_asn_cur INTO @asn
END
CLOSE edi_asn_cur
DEALLOCATE edi_asn_cur

--CLEAR THE PRINTING TABLE
TRUNCATE TABLE #tdc_asn_text_print

--PROCESS THE ASN'S
DECLARE process_asn_cursor CURSOR FAST_FORWARD READ_ONLY FOR
	SELECT serial_no, gross_wt FROM #int_list_in ORDER BY serial_no
OPEN process_asn_cursor
FETCH NEXT FROM process_asn_cursor INTO @asn, @gross_wt
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @ret = tdc_process_asn_sp @asn, @gross_wt, @err_msg OUTPUT
	IF @ret < 0
	BEGIN
		CLOSE process_asn_cursor
		DEALLOCATE process_asn_cursor
		RETURN @ret
	END
	ELSE
	BEGIN
		--COPY THE OUTPUT FROM THE TEMP TABLE INTO THE TEMP ASN PRINT TABLE
		INSERT INTO #tdc_asn_text_print
			SELECT * FROM #tdc_asn_text ORDER BY row_num
	END
	FETCH NEXT FROM process_asn_cursor INTO @asn, @gross_wt
END
CLOSE process_asn_cursor
DEALLOCATE process_asn_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_edi_process_all] TO [public]
GO
