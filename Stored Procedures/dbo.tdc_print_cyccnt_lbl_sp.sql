SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_cyccnt_lbl_sp]
			@user_id varchar(50),
			@station_id varchar(3),
			@team_id varchar(20) ,
			@location  varchar(10),
			@trans_source varchar(2) = 'CO'
AS


	--variables	
DECLARE	@LP_WHO_ENTERED VARCHAR (20), 		@LP_DATE_ENTERED DATETIME ,		@LP_NOTES VARCHAR (255)  ,	
	@LP_LOC_NAME VARCHAR (30) ,		@FORMATPHONE VARCHAR (40),		@LP_DESCRIPTION_X VARCHAR (255),
	@LP_LOC_ADDR1 VARCHAR (40),		@LP_LOC_ADDR2 VARCHAR (40),		@LP_LOC_ADDR3 VARCHAR (40),
	@LP_LOC_ADDR4 VARCHAR (40),		@LP_LOC_ADDR5 VARCHAR (40),		@LP_LOC_PHONE VARCHAR (30),
	@LP_RANGE_TYPE VARCHAR (100),		@MODULE VARCHAR(15),
--detail variables--
	@LP_PART_NO_X VARCHAR (30),		@LP_LOT_SER_X VARCHAR (25), 		@LP_BIN_NO_X VARCHAR(12), 
	@LP_ITEM_NOTE_X VARCHAR (255), 		@LP_ITEM_UOM_X CHAR (2), 		@LP_PART_TYPE_X CHAR (1) ,
	@LP_ITEM_SKU_X VARCHAR (30),		@LP_LB_TRACKING_X CHAR (1),		@admqty INT,
	@LP_ITEM_UPC_X VARCHAR (12), 		@LP_CYCLE_DATE  VARCHAR (30), 		@LP_CYCLE_CODE_X VARCHAR (10),
	@LP_ADM_ACTUAL_QTY_X VARCHAR (10), 	@LP_TDC_ACTUAL_QTY_X VARCHAR (10), 	@LP_COUNT_QTY_X VARCHAR (10), 
	@LP_COUNT_DATE_X VARCHAR (30),

--variables for printing
	@format_id              VARCHAR (40),   @printer_id             VARCHAR (30),
	@details_count 		INT,            @max_details_on_page    INT,            
	@printed_details_cnt    INT,            @total_pages            INT,  
	@page_no                INT,            @number_of_copies       INT,
  	@insert_value           VARCHAR (300),	@return_value		INT,		
	@printed_on_the_page    INT, 		@strNewField		VARCHAR (255),
	@log_user INT,				@DATA varchar(7500)

/*
IF EXISTS(SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'disp_qty' AND active = 'Y')
BEGIN
	SELECT @admqty = 1
END
ELSE
BEGIN
	SELECT @admqty = 0
END
*/

SET @MODULE = 'ADH'

IF (SELECT COUNT(*) FROM tdc_config (NOLOCK) WHERE [function] = 'log_all_users' AND UPPER(active) = 'Y') > 0
BEGIN
	SELECT @log_user = 1
END
ELSE
BEGIN
	SELECT @log_user = 0
END


SELECT TOP 1 @LP_CYCLE_DATE = CAST(ISNULL(cycle_date, '')AS VARCHAR(50)), @LP_RANGE_TYPE = 'Count By:' + range_type + '   FROM ' + range_type + ':' +  range_start + ' - TO ' + range_type + ':' + range_end
FROM tdc_phy_cyc_count
WHERE team_id = @team_id AND location = @location
 
Select 	@LP_LOC_NAME = ISNULL(l.[name],''), @LP_LOC_ADDR1 = ISNULL (l.addr1,''), @LP_LOC_ADDR2 = ISNULL (l.addr2,''), 
	@LP_LOC_ADDR3 = ISNULL (l.addr3,''), @LP_LOC_ADDR4 = ISNULL (l.addr4,''), @LP_LOC_ADDR5 = ISNULL (l.addr5,''),
	@LP_LOC_PHONE = ISNULL (l.phone,'')
FROM locations l (NOLOCK) 
WHERE l.location = @location

---- This will format the Location phone number to print on BOL ------------------------------------------

select @FORMATPHONE = '(' + substring(@LP_LOC_PHONE,1,3) + ') ' +
	substring(@LP_LOC_PHONE,4,3) + '-' + substring(@LP_LOC_PHONE,7,4) + ' ext. ' +
	substring(@LP_LOC_PHONE,11,4)
SELECT @LP_LOC_PHONE = ''
SELECT @LP_LOC_PHONE = @FORMATPHONE

----------------------------------------------------------------------------------------------------------

EXEC tdc_parse_string_sp @LP_NOTES, @strNewField OUTPUT
SELECT @LP_NOTES = @strNewField



-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_COUNT_TEAM',          ISNULL(@team_id, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',            ISNULL(@location, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_STAT_ID',        ISNULL(@user_id, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CYCLE_DATE',          ISNULL(@LP_CYCLE_DATE, '' ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_NAME',  @LP_LOC_NAME)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_ADDR1', @LP_LOC_ADDR1)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_ADDR2', @LP_LOC_ADDR2)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_ADDR3', @LP_LOC_ADDR3)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_ADDR4', @LP_LOC_ADDR4)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_ADDR5', @LP_LOC_ADDR5)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOC_PHONE', @LP_LOC_PHONE)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_RANGE_TYPE', ISNULL(@LP_RANGE_TYPE, ''))

	
IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)					
	RETURN
END
------------------------------------------------------------------------------------------------

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'ADH', 'CYCCNTRPT', @trans_source, @user_id

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
	INSERT INTO #tdc_final_lbl (print_value) SELECT '*FORMAT,' + @format_id 
	INSERT INTO #tdc_final_lbl (print_value) SELECT data_field + ',' + data_value FROM #PrintData
			
	IF (@@ERROR <> 0 )
	BEGIN
		CLOSE      print_cursor
		DEALLOCATE print_cursor
		RAISERROR ('Insert into #tdc_final_lbl Failed', 16, 3)					
		RETURN
	END
	-----------------------------------------------------------------------------------------------
	
	-- Get  Count of the Details to be printed
	SELECT 	tc.part_no, ISNULL(im.upc_code, ''), ISNULL(im.sku_no, ''), ISNULL(im.[description], ''), 
		im.uom, ISNULL(im.note, ''), im.lb_tracking,
		ISNULL(tc.lot_ser, ''), ISNULL(tc.bin_no, ''),
		RTRIM(LTRIM(ISNULL(STR(tc.adm_actual_qty, 10, 2), ''))),
		RTRIM(LTRIM(ISNULL(STR(tc.tdc_actual_qty, 10, 2), ''))), 
		RTRIM(LTRIM(ISNULL(STR(tc.count_qty, 10, 2), ''))), tc.cyc_code,
		RTRIM(LTRIM(ISNULL(CAST(tc.count_date AS VARCHAR(30)), '')))
	FROM inv_master im (NOLOCK) INNER JOIN tdc_phy_cyc_count tc (NOLOCK)
	ON im.part_no = tc.part_no
	WHERE tc.location = @location
	AND tc.team_id = @team_id 

	SELECT @details_count = @@ROWCOUNT

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'CYC'   
           AND trans        = 'CYCCNTRPT'
           AND trans_source = 'VB'
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CYC_detl_count'), 4) 
	END
	
	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
	     	     ELSE @details_count / @max_details_on_page + 1	
		END		

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1
	
	-- Get details
	DECLARE detail_cursor CURSOR FOR 
		SELECT 	tc.part_no, ISNULL(im.upc_code, ''), ISNULL(im.sku_no, ''), ISNULL(im.[description], ''), 
			im.uom, ISNULL(im.note, ''), im.lb_tracking,
			ISNULL(tc.lot_ser, ''), ISNULL(tc.bin_no, ''),
			RTRIM(LTRIM(ISNULL(STR(tc.adm_actual_qty, 10, 2), ''))),
			RTRIM(LTRIM(ISNULL(STR(tc.tdc_actual_qty, 10, 2), ''))), 
			RTRIM(LTRIM(ISNULL(STR(tc.count_qty, 10, 2), ''))), tc.cyc_code,
 			RTRIM(LTRIM(ISNULL(CAST(tc.count_date AS VARCHAR(30)), '')))
		FROM inv_master im (NOLOCK) INNER JOIN tdc_phy_cyc_count tc (NOLOCK)
		ON im.part_no = tc.part_no
		WHERE tc.location = @location
		  AND tc.team_id = @team_id AND tc.location = @location
		 ORDER BY tc.bin_no

	OPEN detail_cursor
	
	FETCH NEXT FROM detail_cursor INTO @LP_PART_NO_X, @LP_ITEM_UPC_X, @LP_ITEM_SKU_X, @LP_DESCRIPTION_X, @LP_ITEM_UOM_X, 
					   @LP_ITEM_NOTE_X, @LP_LB_TRACKING_X, @LP_LOT_SER_X, @LP_BIN_NO_X,
					   @LP_ADM_ACTUAL_QTY_X, @LP_TDC_ACTUAL_QTY_X, @LP_COUNT_QTY_X, @LP_CYCLE_CODE_X, @LP_COUNT_DATE_X
		
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

----------------------------------------------------------------------------------------------------------------------
		SELECT @DATA = ''
		SELECT @DATA = 'LP_PART_NO' + ' ' + ISNULL(@LP_PART_NO_X, '') + ', ' + 'LP_ITEM_SKU' + ' ' + ISNULL(@LP_ITEM_SKU_X, '') + ', ' +
				'LP_ITEM_UPC' + ' ' + ISNULL(@LP_ITEM_UPC_X, '') + ', ' + 'LP_ITEM_UOM' + ' ' + ISNULL(@LP_ITEM_UOM_X, '') + ', ' +
				'LP_LB_TRACKING' + ' ' + ISNULL(@LP_LB_TRACKING_X, '') + ', ' + 'LP_BIN_NO' + ' ' + ISNULL(@LP_BIN_NO_X, '')  + ', ' +
				'LP_LOT_SER' + ' ' + ISNULL(@LP_LOT_SER_X, '') + ', ' + 'LP_ADM_ACTUAL_QTY' + ' ' + ISNULL(@LP_ADM_ACTUAL_QTY_X, '') + ', ' + 
				'LP_TDC_ACTUAL_QTY' + ' ' + ISNULL(@LP_TDC_ACTUAL_QTY_X, '') + ', ' + 'LP_COUNT_QTY' + ' ' + ISNULL(@LP_COUNT_QTY_X, '') + ', ' + 
				'LP_LOCATION' + ' ' + ISNULL(@location, '') + ', ' + 'LP_USER_STAT_ID' + ' ' + ISNULL(@user_id, '') + ', ' + 
				'LP_CYCLE_CODE' + ' ' + ISNULL(@LP_CYCLE_CODE_X, '') + ', ' + 
				'LP_COUNT_DATE' + ' ' + ISNULL(@LP_COUNT_DATE_X, '') + ', ' + 'LP_COUNT_TEAM' + ' ' + ISNULL(@team_id, '' )
	
		IF @log_user > 0
		BEGIN
			INSERT INTO dbo.tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext,
						  part_no, lot_ser, bin_no, location, quantity, data)
			VALUES  (GETDATE(), @user_id, @trans_source, @MODULE, 'CYCCNTRPT', '0', '0',
				 ISNULL(@LP_PART_NO_X,''), ISNULL(@LP_LOT_SER_X, ''), ISNULL(@LP_BIN_NO_X,''), ISNULL(@location,''), RTRIM(LTRIM(ISNULL(@LP_COUNT_QTY_X, '0'))), ISNULL(@DATA, '') )
	
	
		END
		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_ITEM_NOTE_X, @strNewField OUTPUT
		SELECT @LP_ITEM_NOTE_X = @strNewField
		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_DESCRIPTION_X, @strNewField OUTPUT
		SELECT @LP_DESCRIPTION_X = @strNewField

		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @LP_PART_NO_X)
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_DESCRIPTION_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_ITEM_UPC_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_ITEM_UPC_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_ITEM_SKU_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_ITEM_SKU_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_ITEM_UOM_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_ITEM_UOM_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_ITEM_NOTE_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_ITEM_NOTE_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_LB_TRACKING_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_LB_TRACKING_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_LOT_SER_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_LOT_SER_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_BIN_NO_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_BIN_NO_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_ADM_ACTUAL_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_ADM_ACTUAL_QTY_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_TDC_ACTUAL_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_TDC_ACTUAL_QTY_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_COUNT_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_COUNT_QTY_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_CYCLE_CODE_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_CYCLE_CODE_X, ''))
		INSERT INTO #tdc_final_lbl (print_value) VALUES('LP_COUNT_DATE_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@LP_COUNT_DATE_X, ''))



 

		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      detail_cursor
			DEALLOCATE detail_cursor
			CLOSE      print_cursor
			DEALLOCATE print_cursor

			RAISERROR ('Insert into #tdc_final_lbl Failed', 16, 4)				
			RETURN
		END
		-----------------------------------------------------------------------------------------------

		-- If we reached max detail lines on the page, print the Footer
		IF @printed_on_the_page = @max_details_on_page
		BEGIN
			-------------- Now let's insert the Footer into the output table -----------------
			INSERT INTO #tdc_final_lbl (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4)))
			INSERT INTO #tdc_final_lbl (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
			INSERT INTO #tdc_final_lbl (print_value) VALUES ('*QUANTITY,1')
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*PRINTLABEL'
	
			IF (@@ERROR <> 0 )
			BEGIN
				CLOSE      detail_cursor
				DEALLOCATE detail_cursor
				CLOSE      print_cursor
				DEALLOCATE print_cursor

				RAISERROR ('Insert into #tdc_final_lbl Failed', 16, 5)					
				RETURN
			END
			-----------------------------------------------------------------------------------
	
			-- Next Page
			SELECT @page_no = @page_no + 1
			SELECT @printed_on_the_page = 0

			IF (@printed_details_cnt < @details_count)
			BEGIN

				-------------- Now let's insert the Header $ Sub Header into the output table -----------------
				INSERT INTO #tdc_final_lbl (print_value) SELECT '*FORMAT,' + @format_id 
				INSERT INTO #tdc_final_lbl (print_value) SELECT data_field + ',' + data_value FROM #PrintData
				--INSERT INTO #tdc_final_lbl (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header
	
				IF (@@ERROR <> 0 )
				BEGIN
					CLOSE      detail_cursor
					DEALLOCATE detail_cursor
					CLOSE      print_cursor
					DEALLOCATE print_cursor
					RAISERROR ('Insert into #tdc_final_lbl Failed', 16, 6)					
					RETURN
				END
				-----------------------------------------------------------------------------------------------
			END
		END -- End of 'If we reached max detail lines on the page'

		-- Next Detail Line
		SELECT @printed_details_cnt = @printed_details_cnt + 1
		SELECT @printed_on_the_page = @printed_on_the_page + 1

		FETCH NEXT FROM detail_cursor INTO @LP_PART_NO_X, @LP_ITEM_UPC_X, @LP_ITEM_SKU_X, @LP_DESCRIPTION_X, @LP_ITEM_UOM_X, 
						   @LP_ITEM_NOTE_X, @LP_LB_TRACKING_X, @LP_LOT_SER_X, @LP_BIN_NO_X,
						   @LP_ADM_ACTUAL_QTY_X, @LP_TDC_ACTUAL_QTY_X, @LP_COUNT_QTY_X, @LP_CYCLE_CODE_X, @LP_COUNT_DATE_X
	END -- End of the detail_cursor

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor
	
	------------------ All the details have been inserted ------------------------------------

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -----------------
		INSERT INTO #tdc_final_lbl (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4)))
		INSERT INTO #tdc_final_lbl (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))
		INSERT INTO #tdc_final_lbl (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
		INSERT INTO #tdc_final_lbl (print_value) VALUES ('*QUANTITY,1')
		INSERT INTO #tdc_final_lbl (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))
		INSERT INTO #tdc_final_lbl (print_value) SELECT '*PRINTLABEL'

		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      print_cursor
			DEALLOCATE print_cursor
			RAISERROR ('Insert into #tdc_final_lbl Failed', 16, 7)		
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
GRANT EXECUTE ON  [dbo].[tdc_print_cyccnt_lbl_sp] TO [public]
GO
