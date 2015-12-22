SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_phyccnt_lbl_sp]
			@user_id varchar(50),
			@station_id varchar(3),
			@phy_batch int,
			@tag1 varchar(10) = 'ALL' ,
			@tag2 varchar(10) = 'ALL' ,
			@trans_source varchar(2) = 'VB'
AS

DECLARE @LP_BATCH_NO VARCHAR (10), 		@LP_DATE_INIT VARCHAR (30), 		@LP_WHO_INIT VARCHAR (25), 
	@LP_BATCH_DESC VARCHAR (255),		@LP_LOC_NAME VARCHAR (30) ,		@FORMATPHONE VARCHAR (40),		
	@LP_LOC_ADDR1 VARCHAR (40),		@LP_LOC_ADDR2 VARCHAR (40),		@LP_LOC_ADDR3 VARCHAR (40),
	@LP_LOC_ADDR4 VARCHAR (40),		@LP_LOC_ADDR5 VARCHAR (40),		@LP_LOC_PHONE VARCHAR (30),
--detail variables--
	@LP_ITEM_NOTE_X VARCHAR (255),   	@LP_TAG_NO_X VARCHAR (10), 		@LP_LOCATION_X VARCHAR (10), 
	@LP_ITEM_X VARCHAR (30),  		@LP_ITEM_DESC_X VARCHAR (255), 		@LP_LB_TRACKING_X CHAR (1),
	@LP_QUANTITY_X VARCHAR (10), 		@LP_ORIG_QTY_X VARCHAR (10), 		@LP_ITEM_UPC_X VARCHAR (12), 
	@LP_ITEM_SKU_X VARCHAR (30),		@LP_ITEM_UOM_X CHAR (2), 		@LP_AVG_COST_X VARCHAR (10), 
	@LP_AVG_DIRECT_DOLRS_X VARCHAR (10), 	@LP_AVG_OVHD_DOLRS_X VARCHAR (10), 	@LP_AVG_UTIL_DOLRS_X VARCHAR (10), 
	@LP_LABOR_X VARCHAR (10), 		@LP_DATE_ENTERED_X VARCHAR (30), 	@LP_WHO_ENTERED_X VARCHAR (25),
	@LP_LOT_SER_X VARCHAR(25),		@LP_BIN_NO_X VARCHAR(12),		@Old_Location VARCHAR(10),

	 		

--variables for printing
	@format_id              VARCHAR (40),   @printer_id             VARCHAR (30),
	@details_count 		INT,            @max_details_on_page    INT,            
	@printed_details_cnt    INT,            @total_pages            INT,  
	@page_no                INT,            @number_of_copies       INT,
  	@insert_value           VARCHAR (300),	@return_value		INT,		
	@printed_on_the_page    INT, 		@strNewField		VARCHAR (255),
	@log_user INT,				@DATA 			varchar(7500),   
	@detail_sql varchar(8000)





SET @detail_sql = 'SELECT DISTINCT p.phy_no, p.location, p.part_no, RTRIM(LTRIM(ISNULL(STR(lb.qty_physical, 10, 2), ''''))),
		  CAST(p.date_entered AS VARCHAR(30)), p.who_entered,
		  RTRIM(LTRIM(ISNULL(STR(p.avg_cost, 10, 2), ''''))), RTRIM(LTRIM(ISNULL(STR(p.avg_direct_dolrs, 10, 2), ''''))),
		  RTRIM(LTRIM(ISNULL(STR(p.avg_ovhd_dolrs, 10, 2), ''''))), RTRIM(LTRIM(ISNULL(STR(p.avg_util_dolrs, 10, 2), ''''))),
		  RTRIM(LTRIM(ISNULL(STR(p.labor, 10, 2), ''''))),
		  orig_qty = CASE WHEN EXISTS(SELECT * FROM config (NOLOCK)WHERE flag = ''INV_PHY_BLIND'' AND value_str = ''YES'')
                 THEN ''**********'' ELSE RTRIM(LTRIM(ISNULL(STR(lb.qty, 10, 2), ''''))) END,
		p.lb_tracking, ISNULL(i.upc_code, ''''), ISNULL(i.sku_no, ''''), ISNULL(i.[description], ''''), i.uom, ISNULL(i.note, '''') ,
		ISNULL(lb.bin_no, ''''), ISNULL(lb.lot_ser, '''') FROM physical p(NOLOCK), lot_bin_phy lb(NOLOCK),inv_master i(NOLOCK)
  		WHERE lb.phy_batch = p.phy_batch AND lb.phy_no = p.phy_no AND i.part_no = p.part_no AND p.phy_batch  = ' + RTRIM(LTRIM(STR(@phy_batch))) 

IF @tag1 <> 'ALL' AND @tag2 <> 'ALL' 
BEGIN
	SET @detail_sql = @detail_sql + ' AND p.phy_no BETWEEN ' + @tag1 + ' AND ' + @tag2
END

SET @detail_sql = @detail_sql + ' UNION 
 		SELECT DISTINCT p.phy_no, p.location, p.part_no, RTRIM(LTRIM(ISNULL(STR(p.qty, 10, 2), ''''))),
		CAST(p.date_entered AS VARCHAR(30)), p.who_entered,
		RTRIM(LTRIM(ISNULL(STR(p.avg_cost, 10, 2), ''''))), RTRIM(LTRIM(ISNULL(STR(p.avg_direct_dolrs, 10, 2), ''''))),
		RTRIM(LTRIM(ISNULL(STR(p.avg_ovhd_dolrs, 10, 2), ''''))), RTRIM(LTRIM(ISNULL(STR(p.avg_util_dolrs, 10, 2), ''''))),
		RTRIM(LTRIM(ISNULL(STR(p.labor, 10, 2), ''''))),
        	orig_qty = CASE WHEN EXISTS(SELECT * FROM config (NOLOCK)WHERE flag = ''INV_PHY_BLIND'' AND value_str = ''YES'')               
                THEN ''**********''  ELSE RTRIM(LTRIM(ISNULL(STR(p.orig_qty, 10, 2), '''')))  END,
		p.lb_tracking, ISNULL(i.upc_code, ''''), ISNULL(i.sku_no, ''''), ISNULL(i.[description], ''''), i.uom, ISNULL(i.note, ''''),
 		'''' AS bin_no, '''' AS lot_ser FROM physical p(NOLOCK), inv_master i(NOLOCK)
  		WHERE i.part_no = p.part_no                 
                AND phy_batch = ' + RTRIM(LTRIM(STR(@phy_batch))) +
                ' AND p.part_no NOT IN (SELECT part_no FROM lot_bin_phy (NOLOCK) WHERE phy_batch = p.phy_batch AND phy_no    = p.phy_no) '


IF @tag1 <> 'ALL' AND @tag2 <> 'ALL' 
BEGIN
	SET @detail_sql = @detail_sql + ' AND p.phy_no BETWEEN ' + @tag1 + ' AND ' + @tag2
END

--print len(@detail_sql)
--PRINT @detail_sql

IF (SELECT COUNT(*) FROM tdc_config (NOLOCK) WHERE [function] = 'log_all_users' AND UPPER(active) = 'Y') > 0
BEGIN
	SELECT @log_user = 1
END
ELSE
BEGIN
	SELECT @log_user = 0
END


--Get HDR info
SELECT 	@LP_BATCH_NO = LTRIM(RTRIM(CAST(@phy_batch AS VARCHAR(10)))), @LP_DATE_INIT = CAST(date_init AS VARCHAR(30)), 
	@LP_WHO_INIT = who_init, @LP_BATCH_DESC = ISNULL([description], '') 
FROM phy_hdr(NOLOCK) WHERE phy_batch = @phy_batch



--------------------------------------------------------------------------------------------------------

-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BATCH_NO',          ISNULL(@LP_BATCH_NO, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_INIT',         ISNULL(@LP_DATE_INIT, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_STAT_ID',      ISNULL(@user_id, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WHO_INIT',          ISNULL(@LP_WHO_INIT, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BATCH_DESC',        ISNULL(@LP_BATCH_DESC, '' ))
	
IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)					
	RETURN
END
------------------------------------------------------------------------------------------------

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'ADH', 'PHYCNT', @trans_source, @station_id

-- IF label hasn't been set up, exit
IF @return_value != 0
BEGIN
	TRUNCATE TABLE #PrintData
	RETURN
END

------------------------------------------------------------------------------------------------

-- Loop through the format_ids
DECLARE print_cursor CURSOR FOR 
	SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output

OPEN print_cursor

FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
	
WHILE (@@FETCH_STATUS = 0)
BEGIN
	-------------- Now let's insert the Header $ Sub Header into the output table -----------------
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
	INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData
			
	IF (@@ERROR <> 0 )
	BEGIN
		CLOSE      print_cursor
		DEALLOCATE print_cursor
		RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 3)					
		RETURN
	END
	-----------------------------------------------------------------------------------------------
	
	-- Get  Count of the Details to be printed
	EXEC(@detail_sql)	
	
	--SELECT @details_count = 1
	SELECT @details_count = @@ROWCOUNT

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'ADH'   
           AND trans        = 'PHYCNT'
           AND trans_source = @trans_source
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'phy_detl_count'), 4) 
	END
	
	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
	     	     ELSE @details_count / @max_details_on_page + 1	
		END		

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1
	
	----- For Order based pack tickets the details are: --------------------------
        ----- part_no, item_description, upc_code, sum_pack_qty, sum_ordered_qty --------------
	DECLARE @detail_cursor_sql varchar(7500)
	SET @detail_cursor_sql = 'DECLARE detail_cursor CURSOR FOR ' + @detail_sql
	EXEC(@detail_cursor_sql)
		 
	OPEN detail_cursor
	--PRINT 'BEFORE'
	FETCH NEXT FROM detail_cursor INTO @LP_TAG_NO_X, @LP_LOCATION_X, @LP_ITEM_X, @LP_QUANTITY_X, @LP_DATE_ENTERED_X, @LP_WHO_ENTERED_X, 
					   @LP_AVG_COST_X, @LP_AVG_DIRECT_DOLRS_X, @LP_AVG_OVHD_DOLRS_X, 
					   @LP_AVG_UTIL_DOLRS_X, @LP_LABOR_X, @LP_ORIG_QTY_X, @LP_LB_TRACKING_X,
					   @LP_ITEM_UPC_X, @LP_ITEM_SKU_X, @LP_ITEM_DESC_X, @LP_ITEM_UOM_X, 
					   @LP_ITEM_NOTE_X, @LP_BIN_NO_X, @LP_LOT_SER_X
	
	SELECT @Old_Location = ''

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

		IF @Old_Location <> @LP_LOCATION_X
		BEGIN
			
			Select 	@LP_LOC_NAME = ISNULL(l.[name],''), @LP_LOC_ADDR1 = ISNULL (l.addr1,''), @LP_LOC_ADDR2 = ISNULL (l.addr2,''), 
				@LP_LOC_ADDR3 = ISNULL (l.addr3,''), @LP_LOC_ADDR4 = ISNULL (l.addr4,''), @LP_LOC_ADDR5 = ISNULL (l.addr5,''),
				@LP_LOC_PHONE = ISNULL (l.phone,'')
			FROM locations l (NOLOCK) 
			WHERE l.location = @LP_LOCATION_X
			
			---- This will format the Location phone number to print ------------------------------------------
			
			select @FORMATPHONE = '(' + substring(@LP_LOC_PHONE,1,3) + ') ' +
				substring(@LP_LOC_PHONE,4,3) + '-' + substring(@LP_LOC_PHONE,7,4) + ' ext. ' +
				substring(@LP_LOC_PHONE,11,4)
			SELECT @LP_LOC_PHONE = ''
			SELECT @LP_LOC_PHONE = @FORMATPHONE		
			SET @Old_Location = @LP_LOCATION_X
		END

		SELECT @DATA = ''
		SELECT @DATA = 'LP_PART_NO' + ' ' + ISNULL(@LP_ITEM_X, '') + ', ' + 'LP_ITEM_SKU' + ' ' + ISNULL(@LP_ITEM_SKU_X, '') + ', ' +
				'LP_ITEM_UPC' + ' ' + ISNULL(@LP_ITEM_UPC_X, '') + ', ' + 'LP_ITEM_UOM' + ' ' + ISNULL(@LP_ITEM_UOM_X, '') + ', ' +
				'LP_LB_TRACKING' + ' ' + ISNULL(@LP_LB_TRACKING_X, '') + ', ' + 'LP_LOT_SER' + ' ' + ISNULL(@LP_LOT_SER_X, '') + ', ' +
				'LP_TAG_NO' + ' ' + ISNULL(@LP_TAG_NO_X, '') + ', ' + 'LP_QUANTITY' + ' ' + ISNULL(@LP_QUANTITY_X, '') + ', ' + 
				'LP_ORIG_QTY' + ' ' + ISNULL(@LP_ORIG_QTY_X, '') + ', ' + 'LP_BATCH_NO' + ' ' + ISNULL(@LP_BATCH_NO, '') + ', ' + 
				'LP_BIN_NO' + ' ' + ISNULL(@LP_BIN_NO_X, '') + ', ' + 'LP_LOCATION' + ' ' + ISNULL(@LP_LOCATION_X, '') + ', ' + 'LP_USER_STAT_ID' + ' ' + ISNULL(@user_id, '') 

	
		IF @log_user > 0
		BEGIN
			INSERT INTO dbo.tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext,
						  part_no, lot_ser, bin_no, location, quantity, data)
			VALUES  (GETDATE(), @user_id, @trans_source, 'ADH', 'PHYCNT', '0', '0',
				 ISNULL(@LP_ITEM_X,''), @LP_LOT_SER_X, @LP_BIN_NO_X, ISNULL(@LP_LOCATION_X,''), RTRIM(LTRIM(ISNULL(@LP_QUANTITY_X, '0'))), ISNULL(@DATA, '') )
	
	
		END

		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_ITEM_NOTE_X, @strNewField OUTPUT
		SELECT @LP_ITEM_NOTE_X = @strNewField
		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_ITEM_DESC_X, @strNewField OUTPUT
		SELECT @LP_ITEM_DESC_X = @strNewField

		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM' + ',' + @LP_ITEM_X)
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESC' + ',' + ISNULL(@LP_ITEM_DESC_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_UPC' + ',' + ISNULL(@LP_ITEM_UPC_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_SKU' + ',' + ISNULL(@LP_ITEM_SKU_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_UOM' + ',' + ISNULL(@LP_ITEM_UOM_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_NOTE'  + ',' + ISNULL(@LP_ITEM_NOTE_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LB_TRACKING'  + ',' + ISNULL(@LP_LB_TRACKING_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LOCATION'  + ',' + ISNULL(@LP_LOCATION_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_TAG_NO'  + ',' + ISNULL(@LP_TAG_NO_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_QUANTITY'  + ',' + ISNULL(@LP_QUANTITY_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORIG_QTY'  + ',' + ISNULL(@LP_ORIG_QTY_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_AVG_COST'  + ',' + ISNULL(@LP_AVG_COST_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_AVG_DIRECT_DOLRS'  + ',' + ISNULL(@LP_AVG_DIRECT_DOLRS_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_AVG_OVHD_DOLRS'  + ',' + ISNULL(@LP_AVG_OVHD_DOLRS_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LABOR'  + ',' + ISNULL(@LP_LABOR_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_AVG_UTIL_DOLRS'  + ',' + ISNULL(@LP_AVG_UTIL_DOLRS_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DATE_ENTERED'  + ',' + ISNULL(@LP_DATE_ENTERED_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_WHO_ENTERED'  + ',' + ISNULL(@LP_WHO_ENTERED_X, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_NAME'  + ',' + ISNULL(@LP_LOC_NAME, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_ADDR1'  + ',' + ISNULL(@LP_LOC_ADDR1, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_ADDR2'  + ',' + ISNULL(@LP_LOC_ADDR2, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_ADDR3'  + ',' + ISNULL(@LP_LOC_ADDR3, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_ADDR4'  + ',' + ISNULL(@LP_LOC_ADDR4, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_ADDR5'  + ',' + ISNULL(@LP_LOC_ADDR5, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOC_PHONE'  + ',' + ISNULL(@LP_LOC_PHONE, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_BIN_NO'  + ',' + ISNULL(@LP_BIN_NO_X, '' ))
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('LP_LOT_SER'  + ',' + ISNULL(@LP_LOT_SER_X, '' ))


 
		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      detail_cursor
			DEALLOCATE detail_cursor
			CLOSE      print_cursor
			DEALLOCATE print_cursor

			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 4)				
			RETURN
		END
		-----------------------------------------------------------------------------------------------

		-- If we reached max detail lines on the page, print the Footer
		IF @printed_on_the_page = @max_details_on_page
		BEGIN
			-------------- Now let's insert the Footer into the output table -----------------
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
			INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'
	
			IF (@@ERROR <> 0 )
			BEGIN
				CLOSE      detail_cursor
				DEALLOCATE detail_cursor
				CLOSE      print_cursor
				DEALLOCATE print_cursor

				RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 5)					
				RETURN
			END
			-----------------------------------------------------------------------------------
	
			-- Next Page
			SELECT @page_no = @page_no + 1
			SELECT @printed_on_the_page = 0

			IF (@printed_details_cnt < @details_count)
			BEGIN

				-------------- Now let's insert the Header $ Sub Header into the output table -----------------
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
				INSERT INTO #tdc_print_ticket (print_value) SELECT ISNULL(data_field, '') + ',' + data_value FROM #PrintData
				--INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header
	
				IF (@@ERROR <> 0 )
				BEGIN
					CLOSE      detail_cursor
					DEALLOCATE detail_cursor
					CLOSE      print_cursor
					DEALLOCATE print_cursor
					RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 6)					
					RETURN
				END
				-----------------------------------------------------------------------------------------------
			END
		END -- End of 'If we reached max detail lines on the page'

		-- Next Detail Line
		SELECT @printed_details_cnt = @printed_details_cnt + 1
		SELECT @printed_on_the_page = @printed_on_the_page + 1

		FETCH NEXT FROM detail_cursor INTO @LP_TAG_NO_X, @LP_LOCATION_X, @LP_ITEM_X, @LP_QUANTITY_X, @LP_DATE_ENTERED_X, @LP_WHO_ENTERED_X, 
						   @LP_AVG_COST_X, @LP_AVG_DIRECT_DOLRS_X, @LP_AVG_OVHD_DOLRS_X, 
						   @LP_AVG_UTIL_DOLRS_X, @LP_LABOR_X, @LP_ORIG_QTY_X, @LP_LB_TRACKING_X,
						   @LP_ITEM_UPC_X, @LP_ITEM_SKU_X, @LP_ITEM_DESC_X, @LP_ITEM_UOM_X, 
						   @LP_ITEM_NOTE_X, @LP_BIN_NO_X, @LP_LOT_SER_X

	END -- End of the detail_cursor

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor
	
	------------------ All the details have been inserted ------------------------------------

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -----------------
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      print_cursor
			DEALLOCATE print_cursor
			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 7)		
			RETURN
		END
	END
	-----------------------------------------------------------------------------------------------
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_print_phyccnt_lbl_sp] TO [public]
GO
