SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_build_plan_routing_sp](
			@user_id    varchar(50),
			@station_id varchar(20),
			@part_no varchar(30))

AS

-------------------------------------
DECLARE	@LP_DESCRIPTION 	VARCHAR (255),	@LP_SEQ_NO_X 		VARCHAR (4), 		
	@LP_PART_NO_X 		VARCHAR (30),	@LP_NOTE_NO_X		VARCHAR (255),
	@LP_NOTE2_NO_X	 	VARCHAR (255),	@LP_NOTE3_NO_X		VARCHAR (255), 
	@LP_NOTE4_NO_X		VARCHAR (255),	@strNewField		VARCHAR (255),
	@format_id              VARCHAR (40),   @printer_id             VARCHAR (30),
	@details_count 		INT,            @max_details_on_page    INT,            
	@printed_details_cnt    INT,            @total_pages            INT,  
	@page_no                INT,            @number_of_copies       INT,
  	@insert_value           VARCHAR (300),	@return_value		INT
  	
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),
	 @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8), 
	 @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15) 

---------------------------------------------------------------------------------------------------------

CREATE TABLE #Temp_PrintData_Output(
	format_id        varchar(40)  NOT NULL,
	printer_id       varchar(30)  NOT NULL,
	number_of_copies int          NOT NULL)

INSERT #Temp_PrintData_Output SELECT * FROM #PrintData_Output
TRUNCATE TABLE #PrintData_Output

-- get format_id, printer_id, and number of copies. stored data in table #PrintData_Output
EXEC @return_value = tdc_print_label_sp 'PLW', 'WOROUTING', 'VB', @station_id

-- IF label hasn't been set up, exit
IF @return_value != 0
BEGIN
	INSERT #PrintData_Output SELECT * FROM #Temp_PrintData_Output
	RETURN
END

TRUNCATE TABLE #PrintData

CREATE TABLE #temp_print_ticket (
	row_id      int identity (1,1)  NOT NULL, 
	print_value varchar(300)        NOT NULL)

----------------------------------------------------------------------------------------------------------
SELECT @LP_DESCRIPTION = [description] FROM inv_master (nolock) WHERE part_no = @part_no

-- Get header information
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PART_NO', @part_no)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DESCRIPTION', @LP_DESCRIPTION)

-- Get Count of the Details to be printed
SELECT @details_count = count(*) FROM what_part (nolock) WHERE asm_no = @part_no

----------------------------------
-- Get Max Detail Lines on a page.           
----------------------------------
SET @max_details_on_page = 0

-- First check if user defined the number of details for the format ID
SELECT @max_details_on_page = detail_lines    
  FROM tdc_tx_print_detail_config (NOLOCK)  
 WHERE module       = 'PLW'   
   AND trans        = 'WOROUTING'
   AND trans_source = 'VB'
   AND format_id    = @format_id

-- If not defined, get the value from tdc_config
IF ISNULL(@max_details_on_page, 0) = 0
BEGIN
	-- If not defined, default to 4
	SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'WO_Routing_Detl_Cnt'), 4) 
END	

-- Get Total Pages
SELECT @total_pages = 
	CASE WHEN @details_count % @max_details_on_page = 0 
	     THEN @details_count / @max_details_on_page		
     	     ELSE @details_count / @max_details_on_page + 1
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
	INSERT INTO #temp_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
	INSERT INTO #temp_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData
	-----------------------------------------------------------------------------------------------

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1

	DECLARE detail_cursor CURSOR FOR 
		SELECT seq_no, part_no, note, note2, note3, note4 
			FROM what_part (nolock) WHERE asm_no = @part_no
		 
	OPEN detail_cursor
	
	FETCH NEXT FROM detail_cursor 
		INTO @LP_SEQ_NO_X, @LP_PART_NO_X, @LP_NOTE_NO_X, @LP_NOTE2_NO_X, @LP_NOTE3_NO_X, @LP_NOTE4_NO_X

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_NOTE_NO_X, @strNewField  OUT
		SELECT @LP_NOTE_NO_X = @strNewField

		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_NOTE2_NO_X, @strNewField OUT
		SELECT @LP_NOTE2_NO_X = @strNewField

		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_NOTE3_NO_X, @strNewField OUT
		SELECT @LP_NOTE3_NO_X = @strNewField

		SELECT @strNewField = ''
		EXEC tdc_parse_string_sp @LP_NOTE4_NO_X, @strNewField OUT
		SELECT @LP_NOTE4_NO_X = @strNewField

		SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''), 
			@weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet 
			FROM inv_master (nolock) WHERE part_no = @LP_PART_NO_X
			
		SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''), 
			@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '') 
			FROM inv_master_add (nolock) WHERE part_no = @LP_PART_NO_X

		-------------- Now let's insert the Details into the output table -----------------
		INSERT INTO #temp_print_ticket (print_value) VALUES('LP_SEQ_NO_'   + RTRIM(CAST(@printed_details_cnt AS char(2))) + ',' + ISNULL(@LP_SEQ_NO_X,  ''))		
		INSERT INTO #temp_print_ticket (print_value) VALUES('LP_PART_NO_'  + RTRIM(CAST(@printed_details_cnt AS char(2))) + ',' + ISNULL(@LP_PART_NO_X, ''))
		INSERT INTO #temp_print_ticket (print_value) VALUES('LP_NOTE_NO_'  + RTRIM(CAST(@printed_details_cnt AS char(2))) + ',' + ISNULL(@LP_NOTE_NO_X, ''))
		INSERT INTO #temp_print_ticket (print_value) VALUES('LP_NOTE2_NO_' + RTRIM(CAST(@printed_details_cnt AS char(2))) + ',' + ISNULL(@LP_NOTE2_NO_X, ''))
		INSERT INTO #temp_print_ticket (print_value) VALUES('LP_NOTE3_NO_' + RTRIM(CAST(@printed_details_cnt AS char(2))) + ',' + ISNULL(@LP_NOTE3_NO_X, ''))
		INSERT INTO #temp_print_ticket (print_value) VALUES('LP_NOTE4_NO_' + RTRIM(CAST(@printed_details_cnt AS char(2))) + ',' + ISNULL(@LP_NOTE4_NO_X, ''))
		
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_SKU_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@sku_code, '')
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_HEIGHT_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + CAST(@height AS varchar(20))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_WIDTH_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + CAST(@width AS varchar(20))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CUBIC_FEET_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + CAST(@cubic_feet AS varchar(20))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_LENGTH_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + CAST(@length AS varchar(20))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CMDTY_CODE_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@cmdty_code, '')
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_WEIGHT_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + CAST(@weight_ea AS varchar(20))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_SO_QTY_INCR_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + CAST(@so_qty_increment AS varchar(20))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CATEGORY_1_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@category_1, '')
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CATEGORY_2_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@category_2, '')
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CATEGORY_3_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@category_3, '')
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CATEGORY_4_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@category_4, '')
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_CATEGORY_5_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@category_5, '')

		IF @printed_details_cnt >= @max_details_on_page
		BEGIN
			SELECT @printed_details_cnt = 1

			-------------- Now let's insert the Footer into the output table -----------------
			INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(3)))
			INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(3)))
			INSERT INTO #temp_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
			INSERT INTO #temp_print_ticket (print_value) VALUES ('*QUANTITY,1')
			INSERT INTO #temp_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))
			INSERT INTO #temp_print_ticket (print_value) SELECT '*PRINTLABEL'
			-----------------------------------------------------------------------------------
	
			-- Next Page
			SELECT @page_no = @page_no + 1

			IF (@page_no <= @total_pages)
			BEGIN
				-------------- Now let's insert the Header $ Sub Header into the output table -----------------
				INSERT INTO #temp_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
				INSERT INTO #temp_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData				
				-----------------------------------------------------------------------------------------------
			END
		END
		ELSE
		BEGIN
			SELECT @printed_details_cnt = @printed_details_cnt + 1
		END

		FETCH NEXT FROM detail_cursor 
			INTO @LP_SEQ_NO_X, @LP_PART_NO_X, @LP_NOTE_NO_X, @LP_NOTE2_NO_X, @LP_NOTE3_NO_X, @LP_NOTE4_NO_X
	END -- End of the detail_cursor

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor
	
	------------------ All the details have been inserted ------------------------------------

	IF @page_no = @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -----------------
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(3)))
		INSERT INTO #temp_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(3)))
		INSERT INTO #temp_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
		INSERT INTO #temp_print_ticket (print_value) VALUES ('*QUANTITY,1')
		INSERT INTO #temp_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))
		INSERT INTO #temp_print_ticket (print_value) SELECT '*PRINTLABEL'
	END
	-----------------------------------------------------------------------------------------------
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor

INSERT #PrintData_Output SELECT * FROM #Temp_PrintData_Output
INSERT #tdc_print_ticket (print_value) SELECT print_value FROM #temp_print_ticket 

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_print_build_plan_routing_sp] TO [public]
GO
