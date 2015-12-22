SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_plw_wo_pick_ticket_sp]
			@user_id    varchar(50),	
			@station_id varchar(20),	
  			@prod_no    int, 
  			@prod_ext   int
AS

DECLARE @total_pages   int,	     @printed_on_the_page int,		@est_no		     varchar(10),
	@details_count int,          @max_details_on_page int,          @printed_details_cnt int,        
	@page_no       int,          @number_of_copies    int,          @location            varchar(50),
	@prod_plus_ext varchar(50),  @part_no             varchar(30),  @description         varchar(275),
	@mfg_note      varchar(275), @note                varchar(275), @date_entered        varchar(30), 
	@prod_date     varchar(30),  @sch_date            varchar(30),  @qty_scheduled       varchar(20), 
        @qty           varchar(20),  @prod_type           varchar(50),  @uom                 varchar(20), 
	@staging_area  varchar(60),  @format_id           varchar(40),  @printer_id          varchar(30),
	@line_no       varchar(6),   @seq_no              varchar(10),  @part_no_x           varchar(30), 
	@description_x varchar(275), @uom_x               varchar(20),  @plan_qty            varchar(20),
	@used_qty      varchar(20),  @lot_ser             varchar(24),  @bin_no              varchar(12),  
	@note_x        varchar(275), @comment             varchar(275), @return_value        int,
        @order_by_val  varchar(30),  @order_by_clause     varchar(50),  @cursor_statement    varchar(5000),
        @tran_id       varchar(10),  @dest_bin		  varchar(12),	@topick              varchar(20),
	@print_cnt     varchar(10),  @date_expires	  datetime

DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),
	 @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8), 
	 @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15) 

----------------- Header Data --------------------------------------
-- Now retrieve the Orders information
SELECT  DISTINCT 
	@location      = a.location,     
	@prod_plus_ext = CAST(a.prod_no  AS varchar(10)) + '-' + CAST(a.prod_ext AS varchar(10)),  
    	@part_no       = a.part_no,      
	@description   = a.[description],
	@mfg_note      = REPLACE(a.note, CHAR(13), '/'),        
	@note          = REPLACE(b.note, CHAR(13), '/'),         
	@date_entered  = CAST(a.date_entered  AS varchar(50)), 
	@prod_date     = CAST(a.prod_date     AS varchar(50)), 
	@sch_date      = CAST(a.sch_date      AS varchar(50)), 
	@qty_scheduled = CAST(a.qty_scheduled AS varchar(20)), 
	@qty           = CAST(a.qty           AS varchar(20)), 
	@est_no        = CAST(a.est_no        AS varchar(10)), 
	@prod_type     = a.prod_type,    
	@uom           = a.uom,          
	@staging_area  = a.staging_area,
	@print_cnt       = CASE WHEN
        				(SELECT COUNT(*) FROM tdc_print_history_tbl c
		      			  WHERE c.order_no       = a.prod_no 
					    AND c.order_ext      = a.prod_ext 
					    AND c.location       = a.location 
					    AND pick_ticket_type = 'W' ) > 0 
			 	THEN 'RE-PRINT' 
			 	ELSE 'NEW' 
		     	   END

  FROM  produce a (NOLOCK), inv_master b (NOLOCK)
 WHERE  prod_no   = @prod_no
   AND  prod_ext  = @prod_ext
   AND  a.part_no = b.part_no

-- Remove the '0' after the '.'
EXEC tdc_trim_zeros_sp @qty_scheduled OUTPUT
EXEC tdc_trim_zeros_sp @qty           OUTPUT

EXEC tdc_parse_string_sp @description, @description output	
EXEC tdc_parse_string_sp @note,        @note        output	
EXEC tdc_parse_string_sp @mfg_note,    @mfg_note    output
	
SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''), 
	@weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet 
	FROM inv_master (nolock) WHERE part_no = @part_no
	
SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''), 
	@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '') 
	FROM inv_master_add (nolock) WHERE part_no = @part_no

-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_ENTERED',  ISNULL(@date_entered,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DESCRIPTION',   ISNULL(@description,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',      ISNULL(@location,		'')) 
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_MFG_NOTE',      ISNULL(@mfg_note,		'')) 
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NOTE',          ISNULL(@note,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PART_NO', 	    ISNULL(@part_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROD_DATE',     ISNULL(@prod_date,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROD_EXT',	    ISNULL(@prod_ext,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROD_NO',       ISNULL(@prod_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROD_PLUS_EXT', ISNULL(@prod_plus_ext,	''))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROD_TYPE',     ISNULL(@prod_type,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_QTY',           ISNULL(@qty,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_QTY_SCHEDULED', ISNULL(@qty_scheduled,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_DATE',      ISNULL(@sch_date,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STAGING_AREA',  ISNULL(@staging_area,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_UOM',           ISNULL(@uom,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_EST_NO',        ISNULL(@est_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID', 	    ISNULL(@user_id,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PRINT_CNT',     ISNULL(@print_cnt,  	''))

INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SKU', ISNULL(@sku_code, ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_HEIGHT', CAST(@height AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WIDTH', CAST(@width AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUBIC_FEET', CAST(@cubic_feet AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LENGTH', CAST(@length AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CMDTY_CODE', ISNULL(@cmdty_code, ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT', CAST(@weight_ea AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SO_QTY_INCR', CAST(@so_qty_increment AS varchar(20)))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CATEGORY_1', ISNULL(@category_1, ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CATEGORY_2', ISNULL(@category_2, ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CATEGORY_3', ISNULL(@category_3, ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CATEGORY_4', ISNULL(@category_4, ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CATEGORY_5', ISNULL(@category_5, ''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)			
	RETURN
END
--------------------------------------------------------------------------------------------------

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PLW', 'WOPICKTKT', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PLW', 'WOPICKTKT', 'VB', @user_id
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
	SELECT @details_count = COUNT(CAST(line_no AS varchar(5)) + part_no + ISNULL(lot_ser, '')  + ISNULL(bin_no, ''))
	  FROM tdc_soft_alloc_tbl (NOLOCK) 
	 WHERE order_no   = @prod_no
	   AND order_ext  = @prod_ext
	   AND order_type = 'W'

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
           AND trans        = 'WOPICKTKT'
           AND trans_source = 'VB'
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'WO_Pick_Detl_Count'), 4) 
	END

	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
	     	     ELSE @details_count / @max_details_on_page + 1	
		END		
        
	IF @order_by_val IS NULL
	BEGIN
        	SELECT @order_by_val = ISNULL((SELECT value_str FROM tdc_config WHERE [function] = 'wo_picktkt_sort' AND [active] = 'Y'),'0')
	END

        SELECT @order_by_clause =
                CASE WHEN @order_by_val = 'LIFO'          THEN ' ORDER BY date_expires DESC'
                     WHEN @order_by_val = 'FIFO'          THEN ' ORDER BY date_expires ASC'
                     WHEN @order_by_val = 'LOT/BIN ASC'   THEN ' ORDER BY d.bin_no ASC'
                     WHEN @order_by_val = 'LOT/BIN DESC'  THEN ' ORDER BY d.bin_no DESC'
                     WHEN @order_by_val = 'QTY. ASC'      THEN ' ORDER BY topick ASC'
                     WHEN @order_by_val = 'QTY. DESC'     THEN ' ORDER BY topick DESC'
                     WHEN @order_by_val = 'LINE NO. ASC'  THEN ' ORDER BY d.line_no ASC'
                     WHEN @order_by_val = 'LINE NO. DESC' THEN ' ORDER BY d.line_no DESC'
                                                          ELSE ' ORDER BY d.line_no ASC'
                END

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1
        --SCR 36792  07-19-06 ToddR Below added AND b.lb_tracking 	 = ''N''   plus AND d.part_no         = e.part_no
	-- Declare cursor as a string so we can dynamically change ORDER BY clause
	SELECT @cursor_statement = 
	'DECLARE detail_cursor CURSOR FOR 
		SELECT d.line_no, b.seq_no, d.part_no, b.[description], b.uom, 
		       CAST(b.plan_qty AS varchar(20)) plan_qty, 
		       CAST(b.used_qty AS varchar(20)) used_qty,
		       d.lot, d.bin_no, c.note, b.note, d.next_op, d.tran_id, 
		       CAST(d.qty_to_process AS varchar(20)) topick,
		       '''' date_expires
		  FROM prod_list          b (NOLOCK), 
		       inv_master         c (NOLOCK), 
		       tdc_pick_queue     d (NOLOCK)
		 WHERE d.trans_type_no   = b.prod_no 
		   AND d.trans_type_ext  = b.prod_ext 
		   AND d.line_no    	 = b.line_no  
		   AND d.part_no         = c.part_no
		   AND d.trans_type_no   = ' + cast(@prod_no as varchar(30)) + 
		 ' AND d.trans_type_ext  = ' + cast(@prod_ext as varchar(4)) + 
		 ' AND d.trans_source    = ''PLW'' 
		   AND d.trans           = ''WOPPICK''
		   AND d.tx_lock         = ''R''
               	   AND b.lb_tracking 	 = ''N'' 
                 UNION 
		SELECT d.line_no, b.seq_no, d.part_no, b.[description], b.uom, 
		       CAST(b.plan_qty AS varchar(20)), CAST(b.used_qty AS varchar(20)),
		       d.lot, d.bin_no, c.note, b.note, d.next_op, d.tran_id, 
		       CAST(d.qty_to_process AS varchar(20)) topick,
		       date_expires
		  FROM prod_list      b (NOLOCK), 
                       inv_master     c (NOLOCK), 
                       tdc_pick_queue d (NOLOCK),
		       lot_bin_stock  e (NOLOCK) 
		 WHERE d.trans_type_no   = b.prod_no 
		   AND d.trans_type_ext  = b.prod_ext 
		   AND d.line_no    	 = b.line_no  
		   AND d.part_no         = c.part_no
 		   AND d.part_no         = e.part_no
		   AND d.lot             = e.lot_ser
		   AND d.bin_no          = e.bin_no
		   AND d.location        = e.location
		   AND d.trans_type_no   = ' + cast(@prod_no as varchar(30)) + 
		 ' AND d.trans_type_ext  = ' + cast(@prod_ext as varchar(4)) + 
		 ' AND d.trans_source    = ''PLW'' 
		   AND d.trans           = ''WOPPICK''
		   AND d.tx_lock         = ''R'' '

        EXEC (@cursor_statement + @order_by_clause)

	OPEN detail_cursor

	FETCH NEXT FROM detail_cursor INTO 
		@line_no,  @seq_no,  @part_no_x, @description_x, @uom_x, @plan_qty,
		@used_qty, @lot_ser, @bin_no,    @note_x,        @comment, @dest_bin, @tran_id, @topick, @date_expires

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-- Remove the '0' after the '.'
		EXEC tdc_trim_zeros_sp @plan_qty OUTPUT
		EXEC tdc_trim_zeros_sp @used_qty OUTPUT
		EXEC tdc_trim_zeros_sp @topick   OUTPUT

		EXEC tdc_parse_string_sp @description_x, @description_x output	
		EXEC tdc_parse_string_sp @note_x,        @note_x        output	
		EXEC tdc_parse_string_sp @comment,       @comment       output	
		
		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@bin_no, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_COMMENT_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@comment, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@description_x, 	'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@line_no, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@lot_ser, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_NOTE_'        + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@note_x, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@part_no_x, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PLAN_QTY_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@plan_qty, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_USED_QTY_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@used_qty, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@topick, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SEQ_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@seq_no, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_UOM_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@uom_x, 		'')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TRAN_ID_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@tran_id,            '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DEST_BIN_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@dest_bin,           '')

		SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''), 
			@weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet 
			FROM inv_master (nolock) WHERE part_no = @part_no_x
			
		SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''), 
			@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '') 
			FROM inv_master_add (nolock) WHERE part_no = @part_no_x

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

		IF (@@ERROR <> 0 )
		BEGIN
			CLOSE      detail_cursor
			DEALLOCATE detail_cursor
			CLOSE      print_cursor
			DEALLOCATE print_cursor
			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 3)				
			RETURN
		END
		-------------------------------------------------------------------------------------------------------------------

		-- If we reached max detail lines on the page, print the Footer
		IF @printed_on_the_page = @max_details_on_page
		BEGIN
			-------------- Now let's insert the Footer into the output table -------------------------------------------------
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
				RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 4)					
				RETURN
			END
			-------------------------------------------------------------------------------------------------------------------
			
			-- Next Page
			SELECT @page_no = @page_no + 1, @printed_on_the_page = 0

			IF (@printed_details_cnt < @details_count)
			BEGIN
				-------------- Now let's insert the Header into the output table -------------------------------
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData
			
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
			END
		END
		
		--Next Detail Line
		SELECT @printed_details_cnt = @printed_details_cnt + 1
		SELECT @printed_on_the_page = @printed_on_the_page + 1

		FETCH NEXT FROM detail_cursor INTO 
			@line_no,  @seq_no,  @part_no_x, @description_x, @uom_x, @plan_qty,
			@used_qty, @lot_ser, @bin_no,    @note_x,        @comment, @dest_bin, @tran_id, @topick, @date_expires
	END

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -------------------------------------------------
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
			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 6)		
			RETURN
		END
		-----------------------------------------------------------------------------------------------
	END

	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor

IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'wo_routing_detl_cnt' AND active = 'Y')
	EXEC tdc_print_build_plan_routing_sp @user_id, @station_id, @part_no

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_print_plw_wo_pick_ticket_sp] TO [public]
GO
