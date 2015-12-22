SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_plw_so_cons_pick_ticket_sp]
			@user_id    varchar(50),
			@station_id varchar(20),
			@cons_no    int
AS

DECLARE @printed_on_the_page int,     @printed_details_cnt int,   
	@details_count int,           @max_details_on_page int,                 
	@page_no       int,           @number_of_copies    int,            
	@total_pages   int,           @return_value        int,
	@description   varchar(275),  @part_no             varchar(30),
	@uom           varchar(25),   @format_id           varchar(40),    
	@topick        varchar(20),   @printer_id          varchar(30),
	@print_cnt     varchar(10),  
        @tran_id       varchar(10),   @bin_no              varchar(12),   
	@lot_ser       varchar(24),   @dest_bin            varchar(12),
	@line_no       int,	      @part_type           char(1)
	

----------------- Header Data --------------------------------------
SELECT  @description = [description], 
	@print_cnt   = CASE WHEN EXISTS (SELECT * FROM tdc_print_history_tbl (NOLOCK)
			                  WHERE order_no         = @cons_no
			                    AND order_ext        = 0
				            AND pick_ticket_type = 'C')  -- 'C' means consolidated ticket
			    THEN 'RE-PRINT' 
			    ELSE 'NEW' 
		       END
  FROM tdc_main  (NOLOCK)
 WHERE consolidation_no = @cons_no
   AND order_type       = 'S'

EXEC tdc_parse_string_sp @description, @description output	

-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CONS_NO',     @cons_no                 )
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DESCRIPTION', ISNULL(@description,	'')) 
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PRINT_CNT',   @print_cnt   		   )
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID', 	  @user_id     		   )

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)			
	RETURN
END

--------------------------------------------------------------------------------------------------
-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PLW', 'CONSTKT', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PLW', 'CONSTKT', 'VB', @user_id
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
         WHERE trans_type_no = @cons_no                 
           AND trans IN ('PLWB2B', 'MGTB2B')

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'PLW'   
           AND trans        = 'CONSTKT'
           AND trans_source = 'VB'
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'SO_Cons_Detl_Count'), 4) 
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
		SELECT a.tran_id, a.part_no, a.lot, a.bin_no, a.next_op, a.qty_to_process,
		       b.[description], b.uom, b.status
		  FROM tdc_pick_queue a (NOLOCK),
		       inv_master     b (NOLOCK)
                 WHERE a.trans_type_no = @cons_no
	           AND trans IN ('PLWB2B', 'MGTB2B')
                   AND a.part_no       = b.part_no
		 ORDER BY a.lot, a.bin_no, a.next_op

	OPEN detail_cursor

	FETCH NEXT FROM detail_cursor INTO 
		@tran_id, @part_no, @lot_ser, @bin_no, @dest_bin, @topick, @description, @uom, @part_type

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-- Remove the '0' after the '.'
		EXEC tdc_trim_zeros_sp @topick  OUTPUT

		-------------- Now let's insert the Details into the output table -----------------	
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TRAN_ID_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@tran_id,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@part_no,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@lot_ser,     '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@bin_no,      '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DEST_BIN_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@dest_bin,    '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@topick,      '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_TYPE_'   + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@part_type,   '')			
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@description, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_UOM_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@uom,         '')

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
			-------------------------------------------------------------------------------------------------------------------
			
			-- Next Page
			SELECT @page_no = @page_no + 1
			SELECT @printed_on_the_page = 0

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

		FETCH NEXT FROM detail_cursor INTO 
			@tran_id, @part_no, @lot_ser, @bin_no, @dest_bin, @topick, @description, @uom, @part_type
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
GRANT EXECUTE ON  [dbo].[tdc_print_plw_so_cons_pick_ticket_sp] TO [public]
GO
