SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 04/11/2011 - Fix line number issue

CREATE PROCEDURE [dbo].[tdc_print_plw_xfer_pick_ticket_sp]
			@user_id    varchar(50),
			@station_id varchar(20),
			@xfer_no   int
AS

DECLARE @printed_on_the_page int,
	@details_count int,           @max_details_on_page int,            @printed_details_cnt int,        
	@page_no       int,           @number_of_copies    int,            @line_no             int,
	@total_pages   int,           @ord_qty             varchar(20),    @topick              varchar(20), 
	@description   varchar(275),  @part_no             varchar(30),	   
	@uom           varchar(25),   @format_id           varchar(40),    @printer_id          varchar(30),
	@kit_id        varchar(30),   @kit_caption         varchar(300),   @part_type           char   (2),
	@ord_plus_ext  varchar(20),    @dest_zone_code	   varchar (8),
	@special_instr varchar(275),  @cust_po             varchar(50),    @dest_bin	        varchar(12),
	@cust_code     varchar(50),   @order_date          varchar(30),    @sch_ship_date       varchar(30),
	@carrier_desc  varchar(50),   @ship_to_name        varchar(50),    @print_cnt 	        varchar(10),
	@ship_to_add_1 varchar(60),   @ship_to_add_2       varchar(60),    @ship_to_add_3       varchar(60),
	@ship_to_city  varchar(60),   @ship_to_country     varchar(60),    @ship_to_state       varchar(40),
	@ship_to_zip   varchar(30),   @customer_name       varchar(60),    @addr1               varchar(60),
	@addr2         varchar(60),   @addr3               varchar(60),    @addr4               varchar(60),
	@addr5         varchar(60),   @back_ord_flag	   char   (1),     @zone_desc		varchar(40),  
        @salesperson   varchar(10),   @ship_to_no 	   varchar(10),    @tran_id	        varchar(10),
	@lot_ser       varchar(24),   @bin_no              varchar(12),    @return_value        int,
	@date_entered  varchar(50),   @from_loc 	   varchar(50),    @routing 	        varchar(50),  
	@note          varchar(275),  @req_no              varchar(50),    @shipper_no          varchar(50),
	@to_loc_addr1  varchar(60),   @to_loc_addr2        varchar(60),    @to_loc_addr3        varchar(60), 
	@to_loc_addr4  varchar(60),   @to_loc_addr5        varchar(60),    @name 	        varchar(70),	
	@to_loc_name   varchar(60),   @shipper_name        varchar(70),    @to_loc        	varchar(50),
        @order_by_val  varchar(30),   @order_by_clause     varchar(50),    @cursor_statement    varchar(2000)
	 
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),
	 @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8), 
	 @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15) 

SELECT @printed_on_the_page = 1					-- CVO FIX TM 6.JUL.2011
SELECT @page_no = 1
  
----------------- Header Data ----------------------------------------------------------
SELECT  DISTINCT 
	@date_entered 	= CAST(a.date_entered  AS varchar(50)), 
	@from_loc 	= a.from_loc,
	@note 		= REPLACE(a.note, CHAR(13), '/'), 
	@req_no 	= a.req_no,        
	@routing 	= s.ship_via_name,						--v3.0
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
  FROM  xfers a, locations b, arshipv s			--v3.0
 WHERE  a.xfer_no  = @xfer_no
   AND  a.from_loc = b.location
   AND  a.routing = s.ship_via_code				--v3.0

EXEC tdc_parse_string_sp @Special_Instr, @Special_Instr output	
EXEC tdc_parse_string_sp @Note,          @Note          output	
	 
-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_XFER_NO',         CAST(@xfer_no AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_ENTERED',  ISNULL(@date_entered, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FROM_LOC',      ISNULL(@from_loc, 		'')) 
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NOTE',          ISNULL(@note, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_REQ_NO',        ISNULL(@req_no, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',       ISNULL(@routing, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_SHIP_DATE', ISNULL(@sch_ship_date, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR', ISNULL(@special_instr, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC',        ISNULL(@to_loc, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR1',  ISNULL(@to_loc_addr1, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR2',  ISNULL(@to_loc_addr2, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR3',  ISNULL(@to_loc_addr3, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR4',  ISNULL(@to_loc_addr4, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR5',  ISNULL(@to_loc_addr5, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_NAME',   ISNULL(@to_loc_name, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER_NO',    ISNULL(@shipper_no, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER_NAME',  ISNULL(@shipper_name, 	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NAME',          ISNULL(@name, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR1',	    ISNULL(@addr1, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR2',	    ISNULL(@addr2, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR3',	    ISNULL(@addr3, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR4', 	    ISNULL(@addr4, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR5', 	    ISNULL(@addr5, 		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID',       ISNULL(@user_id, 		''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)			
	RETURN
END

--------------------------------------------------------------------------------------------------
-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PLW', 'XFERPICKTKT', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PLW', 'XFERPICKTKT', 'VB', @user_id
END

-- IF label hasn't been set up for the user id, exit
IF @return_value <> 0
BEGIN
	TRUNCATE TABLE #PrintData
	RETURN
END

-- Loop through the format_ids
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
	-- Get  Count of the Details to be printed
	SELECT @details_count = COUNT(*)
	  FROM tdc_pick_queue (NOLOCK) 
	 WHERE trans_type_no  = @xfer_no
	   AND trans_type_ext = 0
	   AND trans          = 'XFERPICK'
           AND tx_lock        = 'R'

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0
	SET @order_by_val        = NULL

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines, 
               @order_by_val        = print_detail_sort      
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'PLW'   
           AND trans        = 'XFERPICKTKT'
           AND trans_source = 'VB'
           AND format_id    = @format_id
           
	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'Xfer_Pick_Detl_Count'), 4) 
	END

	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
	     	     ELSE @details_count / @max_details_on_page + 1	
		END		
        
	IF @order_by_val IS NULL
	BEGIN
        	SELECT @order_by_val = ISNULL((SELECT value_str FROM tdc_config WHERE [function] = 'Xfer_picktkt_sort' AND [active] = 'Y'),'0')
	END

        SELECT @order_by_clause =
                CASE WHEN @order_by_val = 'LIFO'          THEN ' ORDER BY date_expires DESC'
                     WHEN @order_by_val = 'FIFO'          THEN ' ORDER BY date_expires ASC'
                     WHEN @order_by_val = 'LOT/BIN ASC'   THEN ' ORDER BY a.bin_no ASC'
                     WHEN @order_by_val = 'LOT/BIN DESC'  THEN ' ORDER BY a.bin_no DESC'
                     WHEN @order_by_val = 'QTY. ASC'      THEN ' ORDER BY pick_qty ASC'
                     WHEN @order_by_val = 'QTY. DESC'     THEN ' ORDER BY pick_qty DESC'
                     WHEN @order_by_val = 'LINE NO. ASC'  THEN ' ORDER BY a.line_no ASC'
                     WHEN @order_by_val = 'LINE NO. DESC' THEN ' ORDER BY a.line_no DESC'
                                                          ELSE ' ORDER BY a.line_no ASC'
                END

	-- Declare cursor as a string so we can dynamically change ORDER BY clause
	SELECT @cursor_statement = 
              'DECLARE detail_cursor CURSOR FOR
		SELECT a.part_no, a.line_no, a.lot, a.bin_no, b.uom, b.[description], b.ordered, a.qty_to_process AS TOPICK, a.tran_id
		  FROM tdc_pick_queue a (NOLOCK), 
		       xfer_list      b (NOLOCK)
		 WHERE a.trans_type_no  = ' + CAST(@xfer_no as VARCHAR(30)) +
	         ' AND a.trans_type_ext = 0
		   AND a.trans          = ''XFERPICK''
		   AND a.trans_type_no  = b.xfer_no 
		   AND a.line_no        = b.line_no'

        EXEC (@cursor_statement + @order_by_clause)

	OPEN detail_cursor

	FETCH NEXT FROM detail_cursor INTO @part_no, @line_no, @lot_ser, @bin_no, @uom, @description, @ord_qty, @topick, @tran_id
		           
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-- Remove the '0' after the '.'
		EXEC tdc_trim_zeros_sp @ord_qty OUTPUT
		EXEC tdc_trim_zeros_sp @topick  OUTPUT
		EXEC tdc_parse_string_sp @description,  @description    output	

		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(CAST(@line_no AS varchar(3)), '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TRAN_ID_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@tran_id,    '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_UOM_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@uom,		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@description,'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORD_QTY_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@ord_qty, 	'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@topick, 	'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@part_no, 	'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@lot_ser,    '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@bin_no,     '')

		SELECT @sku_code = isnull(sku_code, ''), @height = isnull(height,0), @width = isnull(width,0), @length = isnull([length],0), @cmdty_code = isnull(cmdty_code, ''), 
			@weight_ea = isnull(weight_ea,0), @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = isnull(cubic_feet,0) 
			FROM inv_master (nolock) WHERE part_no = @part_no
		SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''), 
			@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '') 
			FROM inv_master_add (nolock) WHERE part_no = @part_no

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
		-------------------------------------------------------------------------------------------------------------------

		-- If we reached max detail lines on the page, print the Footer
		IF @printed_on_the_page = @max_details_on_page
		BEGIN
			-------------- Now let's insert the Footer into the output table -------------------------------------------------
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))  --v2.0
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
			-------------------------------------------------------------------------------------------------------------------
			
			-- Next Page
			SELECT @page_no = @page_no + 1
--			SELECT @printed_on_the_page = 1							-- CVO FIX TM 6.JUL.2011
			SELECT @printed_on_the_page = 0							-- v1.1 Needs to be reset to zero as it is incremented at the bottom of the cursor

			IF (@printed_details_cnt < @details_count)
			BEGIN
				-------------- Now let's insert the Header into the output table -----------------
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
		
		--Next Detail Line
		SELECT @printed_details_cnt = @printed_details_cnt + 1
		SELECT @printed_on_the_page = @printed_on_the_page + 1

		FETCH NEXT FROM detail_cursor INTO @part_no, @line_no, @lot_ser, @bin_no, @uom, @description, @ord_qty, @topick, @tran_id
	END

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -------------------------------------------------
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))  --v2.0
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      print_cursor
			DEALLOCATE print_cursor
			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 7)		
			RETURN
		END
		-----------------------------------------------------------------------------------------------
	END

	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_print_plw_xfer_pick_ticket_sp] TO [public]
GO
