SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_xfer_pick_list_sp]
		@user_id      varchar(50),
		@station_id   varchar(20),
		@xfer_no      int
AS

DECLARE @details_count int,           @max_details_on_page int,          @printed_details_cnt int,
	@page_no       int,           @line_no             int,          @number_of_copies    int,
	@ordered       varchar(20),   @total_pages         int,          @shipper_no          varchar(50), 
	@comment       varchar(275),  @description         varchar(275), @note                varchar(275),
        @lot_ser       varchar(24),   @part_no             varchar(30),  @uom                 varchar(25),   
	@from_bin      varchar(12),   @format_id           varchar(40),  @printer_id          varchar(30),
	@date_entered  varchar(50),   @from_loc 	   varchar(50),  @routing 	      varchar(50),  
	@req_no        varchar(50),   @to_loc_name         varchar(60),  @shipper_name        varchar(70),  
	@sch_ship_date varchar(50),   @special_instr	   varchar(300), @to_loc   	      varchar(50), 
	@to_loc_addr1  varchar(60),   @to_loc_addr2        varchar(60),  @to_loc_addr3        varchar(60), 
	@to_loc_addr4  varchar(60),   @to_loc_addr5        varchar(60),  @name 	              varchar(70),	   
	@addr1 	       varchar(60),   @addr2 	           varchar(60),  @addr3	              varchar(60),             
	@addr4	       varchar(60),   @addr5	           varchar(60),  @return_value        int,
	@printed_on_the_page int
	
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),
	 @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8), 
	 @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15) 

----------------- Header Data ----------------------------------------------------------

SELECT  DISTINCT 
	@date_entered 	= CAST(a.date_entered  AS varchar(50)),
	@from_loc 	= a.from_loc,
	@note 		= REPLACE(a.note, CHAR(13), '/'),   
	@req_no 	= a.req_no, 
	@routing 	= a.routing,
	@sch_ship_date 	= CAST(a.sch_ship_date AS varchar(50)), 
	@special_instr 	= REPLACE(a.special_instr, CHAR(13), '/'), 
	@to_loc 	= a.to_loc,      
	@to_loc_addr1 	= a.to_loc_addr1,
	@to_loc_addr2 	= a.to_loc_addr2,
	@to_loc_addr3 	= a.to_loc_addr3,
	@to_loc_addr4 	= a.to_loc_addr4,
	@to_loc_addr5 	= a.to_loc_addr5,
	@to_loc_name 	= a.to_loc_name, 
	@shipper_no 	= a.shipper_no,  
	@shipper_name 	= a.shipper_name,
	@name         	= b.[name],
	@addr1 		= b.addr1,
	@addr2		= b.addr2,
	@addr3 		= b.addr3,
	@addr4 		= b.addr4,
	@addr5 		= b.addr5
  FROM  xfers a, locations b
 WHERE  a.xfer_no  = @xfer_no
   AND  a.from_loc = b.location

EXEC tdc_parse_string_sp @Special_Instr, @Special_Instr output	
EXEC tdc_parse_string_sp @Note,          @Note          output	
	 
-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_XFER_NO',       CAST(@xfer_no AS varchar (20) ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_ENTERED',  ISNULL(@date_entered,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FROM_LOC',      ISNULL(@from_loc,		'')) 
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NOTE',          ISNULL(@note,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_REQ_NO',        ISNULL(@req_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',       ISNULL(@routing,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_SHIP_DATE', ISNULL(@sch_ship_date,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR', ISNULL(@special_instr,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC',        ISNULL(@to_loc,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR1',  ISNULL(@to_loc_addr1,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR2',  ISNULL(@to_loc_addr2,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR3',  ISNULL(@to_loc_addr3,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR4',  ISNULL(@to_loc_addr4,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR5',  ISNULL(@to_loc_addr5,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_NAME',   ISNULL(@to_loc_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER_NO',    ISNULL(@shipper_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER_NAME',  ISNULL(@shipper_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NAME',          ISNULL(@name,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR1',	    ISNULL(@addr1,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR2',	    ISNULL(@addr2,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR3',	    ISNULL(@addr3,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR4', 	    ISNULL(@addr4,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR5', 	    ISNULL(@addr5,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID',       ISNULL(@user_id,		''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)			
	RETURN
END

-- Get Format ID, Printer ID, Number of Copies
EXEC @return_value = tdc_print_label_sp 'DIS', 'XFERPICKTKT', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'DIS', 'XFERPICKTKT', 'VB', @user_id
END

-- IF label hasn't been set up for the user id, exit
IF @return_value <> 0
BEGIN
	TRUNCATE TABLE #PrintData
	RETURN
END

DECLARE print_cursor CURSOR FOR 
	SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output

OPEN print_cursor

FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
	
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	-------------- Now let's insert the Header into the output table -----------------
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
	INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData
			
	IF (@@ERROR <> 0 )
	BEGIN
		CLOSE      print_cursor
		DEALLOCATE print_cursor
		RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 2)					
		RETURN
	END
	-----------------------------------------------------------------------------------------------
	
	------------------------ Detail Data ----------------------------------------------------------
	SELECT DISTINCT 
	       xfer_list.comment, xfer_list.[description], xfer_list.from_bin,
	       xfer_list.line_no, xfer_list.lot_ser,       xfer_list.ordered, 
	       xfer_list.part_no, xfer_list.uom,           inv_master.note 
	  FROM xfer_list 
	 INNER JOIN inv_master ON 
	       xfer_list.part_no = inv_master.part_no 
	 RIGHT OUTER JOIN xfers ON 
	       xfer_list.xfer_no = xfers.xfer_no 
	 WHERE xfers.xfer_no = @xfer_no          
	
	-- Get Details Count
	SELECT @details_count = @@rowcount

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'DIS'   
           AND trans        = 'XFERPICKTKT'
           AND trans_source = 'VB'
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'XferPckListDetlCnt'), 4) 
	END
	
	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
		     ELSE @details_count / @max_details_on_page + 1	
		END		

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1

	DECLARE detail_cursor CURSOR FOR 
		SELECT DISTINCT
		       REPLACE(xfer_list.comment, CHAR(13), '/'), xfer_list.[description], xfer_list.from_bin, xfer_list.line_no, 
		       xfer_list.lot_ser, CAST(xfer_list.ordered AS varchar(20)), xfer_list.part_no, xfer_list.uom, 
		       REPLACE(inv_master.note, CHAR(13), '/')
		  FROM xfer_list 
		 INNER JOIN inv_master  ON xfer_list.part_no = inv_master.part_no 
		 RIGHT OUTER JOIN xfers ON xfer_list.xfer_no = xfers.xfer_no 
		 WHERE xfers.xfer_no = @xfer_no
		 ORDER BY line_no	

	OPEN detail_cursor
	FETCH NEXT FROM detail_cursor INTO 
		@comment, @description, @from_bin, @line_no, @lot_ser, @ordered, @part_no, @uom, @note

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-- Remove the '0' after the '.'
		EXEC tdc_trim_zeros_sp @ordered OUTPUT
		EXEC tdc_parse_string_sp @description, @description output	
		
		SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''), 
			@weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet 
			FROM inv_master (nolock) WHERE part_no = @part_no
			
		SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''), 
			@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '') 
			FROM inv_master_add (nolock) WHERE part_no = @part_no

		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_COMMENT_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@comment,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@description, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_FROM_BIN_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@from_bin,    '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(CAST(@line_no AS varchar(3)), '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@lot_ser,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORDERED_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@ordered,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@part_no,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_UOM_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@uom,         '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_NOTE_'        + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@note,        '')

		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SKU_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@sku_code, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_HEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@height AS varchar(20))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WIDTH_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@width AS varchar(20))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CUBIC_FEET_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@cubic_feet AS varchar(20))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LENGTH_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@length AS varchar(20))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CMDTY_CODE_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cmdty_code, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@weight_ea AS varchar(20))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SO_QTY_INCR_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@so_qty_increment AS varchar(20))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_1_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_1, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_2_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_2, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_3_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_3, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_4_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_4, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_5_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_5, '')
				
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
	
		IF @printed_on_the_page = @max_details_on_page
		BEGIN
			-------------- Now let's insert the Details into the output table -----------------			
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))
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
			-----------------------------------------------------------------------------------------------
			
			-- Next Page
			SELECT @page_no = @page_no + 1
			SELECT @printed_on_the_page = 0

			IF (@printed_details_cnt < @details_count)
			BEGIN
				-------------- Now let's insert the Header into the output table -----------------------------
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData
			
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
		END

		-- Next Detail Line
		SELECT @printed_details_cnt = @printed_details_cnt + 1
		SELECT @printed_on_the_page = @printed_on_the_page + 1

		FETCH NEXT FROM detail_cursor INTO 
			@comment, @description, @from_bin, @line_no, @lot_ser, @ordered, @part_no, @uom, @note
	END

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -----------------
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      detail_cursor
			DEALLOCATE detail_cursor
			CLOSE      print_cursor
			DEALLOCATE print_cursor
			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 7)		
			RETURN
		END
		-----------------------------------------------------------------------------------------------
	END
-------------------------------------------------------------------------------------------------
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_print_xfer_pick_list_sp] TO [public]
GO
