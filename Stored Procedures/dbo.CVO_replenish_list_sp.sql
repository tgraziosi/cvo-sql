SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CVO_replenish_list_sp]
			@group_code    varchar(10)

AS

DECLARE @printed_on_the_page 	int,     	@printed_details_cnt int,   
	@details_count       	int,           	@max_details_on_page int,                 
	@page_no        	int,           	@number_of_copies    int,            
	@total_pages    	int,           	@return_value        int,
	@format_id      	varchar(40),   	@printer_id          varchar(30),    
	--User variables
        @qtran_id              	varchar (30),   @part_no             varchar (30),
	@to_bin_no             	varchar (12),	@lot_ser             varchar (25),
	@from_bin_no            varchar (12),   @qty     decimal (24,8),
	@priority		int



--IF @return_value <> 0
--BEGIN
	TRUNCATE TABLE #PrintData
--	RETURN
--END

-- Loop through the format_ids
DECLARE print_cursor CURSOR FOR 
	SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output

OPEN print_cursor
FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies

WHILE (@@FETCH_STATUS <> -1)
BEGIN
	-------------- Now let's insert the Header into the output table -----------------
--	INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
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
	SELECT @details_count = COUNT(*) from tdc_pick_queue a (nolock), tdc_bin_master b (nolock) 
			where a.next_op = b.bin_no 
			and trans = 'MGTB2B'
			and b.group_code =  @group_code


	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID

--	SELECT @max_details_on_page = detail_lines    
--          FROM tdc_tx_print_detail_config (NOLOCK)  
--         WHERE module       = 'CYC'   
--           AND trans        = 'CYCCOUNT'
--           AND trans_source = 'VB'
--           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CYC_detl_count'), 3) 
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
		SELECT a.tran_id, a.part_no, a.bin_no, a.qty_to_process, a.next_op, a.priority FROM  tdc_pick_queue a (nolock), tdc_bin_master b (nolock) 
			where a.next_op = b.bin_no 
			and trans = 'MGTB2B'
			and b.group_code =  @group_code
			order by a.bin_no,a.priority 

	OPEN detail_cursor

	FETCH NEXT FROM detail_cursor INTO @qtran_id, @part_no, @from_bin_no, @qty,
		@to_bin_no, @priority
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_QTRAN_ID_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@qtran_id, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@part_no, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_FROM_BIN_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(@to_bin_no, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TO_BIN_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 		 ISNULL(@to_bin_no, '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_QTY_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' +  		 ISNULL(cast(@qty as varchar(30)), '')
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PRIORITY_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + 	 ISNULL(cast(@priority as varchar(30)), '')


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
--	INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_USER_STAT_ID,' + @user_id
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
	
		FETCH NEXT FROM detail_cursor INTO @qtran_id, @part_no, @from_bin_no, @qty,
		@to_bin_no, @priority

	END

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -------------------------------------------------
--INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_USER_STAT_ID,' + @user_id
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
GRANT EXECUTE ON  [dbo].[CVO_replenish_list_sp] TO [public]
GO
