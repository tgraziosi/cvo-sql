SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_cyc_count_ticket_sp]
			@user_id    varchar(50),
			@station_id varchar(20)

AS

DECLARE @printed_on_the_page 	int,     	@printed_details_cnt int,   
	@details_count       	int,           	@max_details_on_page int,                 
	@page_no        	int,           	@number_of_copies    int,            
	@total_pages    	int,           	@return_value        int,
	@format_id      	varchar(40),   	@printer_id          varchar(30),    
	--User variables
        @location               varchar (10),   @part_no             varchar (30),
	@lb_tracking        	varchar (2),	@lot_ser             varchar (25),
	@bin_no             	varchar (12),   @erp_current_qty     decimal (24,8),
	@erp_qty_at_count   	decimal (24,8), @post_qty            decimal (24,8),
	@post_ver           	int, 		@changed_flag        int,
	@cost               	varchar (30),   @curr_key            varchar (4),
        @differenc          	decimal (24,0)

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'CYC', 'CYCCNT', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'CYC', 'CYCCOUNT', 'VB', @user_id
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
	SELECT @details_count = COUNT(*) FROM #tdc_cyc_master

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'CYC'   
           AND trans        = 'CYCCOUNT'
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

	DECLARE detail_cursor CURSOR FOR 
-- Begin CVO Change DMoon - sort by bin_no on list
		--SELECT * FROM #tdc_cyc_master (NOLOCK) ORDER BY part_no 
		SELECT * FROM #tdc_cyc_master (NOLOCK) ORDER BY bin_no 
-- End CVO Change DMoon
	OPEN detail_cursor

	FETCH NEXT FROM detail_cursor INTO @location, @part_no, @lb_tracking, @lot_ser,
		@bin_no, @erp_current_qty, @erp_qty_at_count, @post_qty, @post_ver, @changed_flag,
		@cost, @curr_key, @differenc
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOCATION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@location, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@part_no, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LB_TRACKING_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@lb_tracking, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@lot_ser, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 		 ISNULL(@bin_no, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ERP_CURRENT_QTY_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' +  ISNULL(cast(@erp_current_qty as varchar(30)), '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ERP_QTY_AT_COUNT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(cast(@erp_qty_at_count as varchar(30)), '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_POST_QTY_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(cast(@post_qty as varchar(30)), '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_COST_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@cost, '')  

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
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_USER_STAT_ID,' + @user_id
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
	
		FETCH NEXT FROM detail_cursor INTO @location, @part_no, @lb_tracking, @lot_ser,
			@bin_no, @erp_current_qty, @erp_qty_at_count, @post_qty, @post_ver, @changed_flag,
			@cost, @curr_key, @differenc

	END

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -------------------------------------------------
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_USER_STAT_ID,' + @user_id
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
		-----------------------------------------------------------------------------------------------
	END

	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_print_cyc_count_ticket_sp] TO [public]
GO
