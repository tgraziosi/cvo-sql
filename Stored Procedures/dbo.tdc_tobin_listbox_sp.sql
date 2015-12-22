SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_tobin_listbox_sp		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	part_no   - 	Part Number			    		*/
/*	location  - 	To Location			      		*/
/*	from_bin  -	FROM_BIN					*/
/* Output:        					     	 	*/
/*	errmsg	  -	Null if no errors		     	 	*/
/*									*/
/* Description:								*/
/*	This stored procedure generates a table of acceptable bins for 	*/
/*	to_bin list boxes. The list are ordered by default zone, 	*/
/*	bins within the same default zone and like part, and then 	*/
/* 	open bins in the default zone. If the default zone is empy or	*/
/*	'N/A' a list of all active bins in that location are generated	*/
/*									*/
/* Revision History:							*/
/* 	Version	Date		Who	Description				*/
/*	-------	----		---	-----------				*/
/* 	v1.0	2/07/2000	KMH	Initial					*/
/*	v1.1	08/08/2012	CVO	Code changed by CVO to add 'reserve bin' to the list */
/*	v1.2	14/06/2013	CT Issue #695 Don't display RINGFENCE of CROSSDOCK bins */
/*									*/
/************************************************************************/

CREATE PROCEDURE [dbo].[tdc_tobin_listbox_sp](
		@part_no  varchar (30),
		@location varchar (10),
		@from_bin varchar (12)
)
AS
DECLARE @pat_index int,
	@bin_no varchar(30),
	@to_bin varchar(12),
	@partial varchar(4),
	@qty decimal(12,2),
	@row_cnt int,
	@in_stock decimal(20,8),
	@orderby varchar(20),
	@sqlstatement varchar(1000)
	

	-- primary bin
	INSERT INTO #bin_listbox (bin_no, to_bin)
		SELECT bin_no + '<1>', bin_no
		  FROM tdc_bin_part_qty (nolock) 
		 WHERE location = @location 
		   AND part_no = @part_no 
		   AND [primary] = 'Y'
	
	-- secondary bin
	INSERT INTO #bin_listbox (bin_no, to_bin)
		SELECT bin_no + '<2>', bin_no
		  FROM tdc_bin_part_qty (nolock)
		 WHERE location = @location
		   AND part_no = @part_no
		   AND bin_no <> @from_bin
		   AND seq_no > 0
		ORDER BY seq_no

	SELECT @orderby = 
		CASE value_str
			WHEN '1' THEN 'date_expires'
			WHEN '2' THEN 'date_expires desc'
	         	WHEN '3' THEN 'lot_ser'
	         	WHEN '4' THEN 'lot_ser desc'
	         	WHEN '5' THEN 'qty'
		 	WHEN '6' THEN 'qty desc'
	         	ELSE 'bin_no'
		END
	  FROM tdc_config (nolock) 
	 WHERE [function] = 'dist_cust_pick'

-- exec tdc_tobin_listbox_sp 'MFS73', 'DALLAS', 'AA104'
-- select * from #bin_listbox ORDER BY row_cnt
-- select distinct bin_no from lot_bin_stock where location = 'Dallas'

	-- same part in inventory
	SELECT @sqlstatement = 'SELECT s.bin_no + ''<S>'', s.bin_no
				  FROM lot_bin_stock s (nolock), tdc_bin_master m (nolock)
				 WHERE s.location = ' + '''' + @location + '''' + 
				 ' AND s.part_no = ' + '''' + @part_no + '''' +
				 ' AND s.bin_no <> ' + '''' + @from_bin + '''' +
				 ' AND s.location = m.location
				   AND s.bin_no = m.bin_no
				   AND (usage_type_code = ''OPEN'' OR usage_type_code = ''REPLENISH'')
				   AND m.status = ''A'' 		   			  
				   AND s.bin_no NOT IN (SELECT to_bin FROM #bin_listbox)
				ORDER BY s.' + @orderby

	INSERT INTO #bin_listbox (bin_no, to_bin)
		EXEC (@sqlstatement)

-- START v1.1
-- 080812 - tag -- reserve bin if from bin = an 'r' bin
	IF left(@from_bin,1) = 'R' and @location = '001' 
	begin
		INSERT INTO #bin_listbox (bin_no, to_bin)
		SELECT bin_no + '<E>', bin_no
		  FROM tdc_bin_master (nolock) 
		 WHERE location = @location
		   AND (usage_type_code = 'OPEN' OR usage_type_code = 'REPLENISH')
		   AND status = 'A' 
		   AND bin_no = 'reserve bin'			  
		   AND bin_no NOT IN (SELECT to_bin FROM #bin_listbox)
		ORDER BY bin_no
	end
-- END v1.1

-- Make F2 search faster for PO receipt and putaway DMoon 1/25/2011
/*
	-- empty bin (does not exist in inventory)
	INSERT INTO #bin_listbox (bin_no, to_bin)
		SELECT bin_no + '<E>', bin_no
		  FROM tdc_bin_master (nolock) 
		 WHERE location = @location
		   AND (usage_type_code = 'OPEN' OR usage_type_code = 'REPLENISH')
		   AND status = 'A' 
		   AND bin_no <> @from_bin			  
		   AND bin_no NOT IN (SELECT distinct bin_no FROM lot_bin_stock (nolock) WHERE location = @location)
		   AND bin_no NOT IN (SELECT to_bin FROM #bin_listbox)
		ORDER BY bin_no

	-- different part in inventory
	SELECT @sqlstatement = 'SELECT s.bin_no + ''<N>'', s.bin_no
				  FROM lot_bin_stock s (nolock), tdc_bin_master m (nolock)
				 WHERE s.location = ' + '''' + @location + '''' + 
				 ' AND s.part_no != ' + '''' + @part_no + '''' +
				 ' AND s.bin_no <> ' + '''' + @from_bin + '''' +
				 ' AND s.location = m.location
				   AND s.bin_no = m.bin_no
				   AND (usage_type_code = ''OPEN'' OR usage_type_code = ''REPLENISH'')
				   AND m.status = ''A'' 		   			  
				   AND s.bin_no NOT IN (SELECT to_bin FROM #bin_listbox)
				ORDER BY s.' + @orderby

	INSERT INTO #bin_listbox (bin_no, to_bin)
		EXEC (@sqlstatement)
*/

	 -- START v1.2
	 DELETE FROM #bin_listbox WHERE to_bin = 'RINGFENCE'

	 DELETE FROM
		a
	 FROM
		#bin_listbox a
	 INNER JOIN
		dbo.tdc_bin_master b (NOLOCK)
	 ON
		a.to_bin = b.bin_no
	 WHERE
		b.location = @location
		AND b.group_code = 'CROSSDOCK'
	 -- END v1.2

	DECLARE bin_cursor CURSOR FOR
				SELECT to_bin, row_cnt FROM #bin_listbox

	OPEN bin_cursor
	FETCH NEXT FROM bin_cursor INTO @to_bin, @row_cnt

	WHILE(@@FETCH_STATUS = 0)
	BEGIN			
		DELETE FROM #bin_listbox WHERE to_bin = @to_bin AND row_cnt > @row_cnt
		FETCH NEXT FROM bin_cursor INTO @to_bin, @row_cnt
	END

	CLOSE bin_cursor
	DEALLOCATE bin_cursor

	DECLARE bin_cursor CURSOR FOR
				SELECT bin_no, to_bin FROM #bin_listbox

	OPEN bin_cursor
	FETCH NEXT FROM bin_cursor INTO @bin_no, @to_bin

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SELECT @qty = ISNULL( (SELECT qty 
					 FROM tdc_bin_part_qty (nolock) 
					WHERE location = @location 
					  AND part_no = @part_no 
					  AND bin_no = @to_bin), 0)

		SELECT @in_stock = ISNULL( (SELECT sum(qty)
					      FROM lot_bin_stock (nolock)
					     WHERE part_no = @part_no  
					       AND location = @location 
					       AND bin_no = @to_bin  
					    GROUP BY location, part_no, bin_no), 0) 

		SET @partial = NULL
		SELECT @pat_index = 0

		SELECT @pat_index = PATINDEX('%<1>%', @bin_no)
		IF (@pat_index > 0) 
		BEGIN
			SELECT @partial = '<1>'
		END
		ELSE
		BEGIN
			SELECT @pat_index = PATINDEX('%<2>%', @bin_no)
			IF (@pat_index > 0) 
			BEGIN
				SELECT @partial = '<2>'
			END
		END

		IF (@partial IS NOT NULL)
		BEGIN
			IF((@qty - @in_stock) > 0)
			BEGIN
				UPDATE #bin_listbox 
				   SET bin_no = @to_bin + @partial + RTRIM(CAST(CAST((@qty - @in_stock) AS decimal(10,2)) AS varchar(10)))
				 WHERE CURRENT OF bin_cursor 
			END
--			ELSE
--			BEGIN			
--				DELETE FROM #bin_listbox WHERE CURRENT OF bin_cursor
--				INSERT INTO #bin_listbox VALUES(@to_bin + @partial + '0+0', @to_bin) 
--			END
		END
		
		FETCH NEXT FROM bin_cursor INTO @bin_no, @to_bin 
	END

	CLOSE bin_cursor
	DEALLOCATE bin_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_tobin_listbox_sp] TO [public]
GO
