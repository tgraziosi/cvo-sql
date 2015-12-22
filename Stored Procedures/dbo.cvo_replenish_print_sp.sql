SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
   
CREATE PROCEDURE [dbo].[cvo_replenish_print_sp]	@station_id	varchar(20),  
											@user_id    varchar(50),
											@order_by	int  
       
AS          
BEGIN  
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@format_id			varchar(40),
			@return_value		int,
			@printer_id			varchar(30),  
			@number_of_copies	int,  
			@lwlPath			varchar(100),  
			@xp_cmdshell		varchar(1000),
			@max_details_on_page int,
			@row_id				int,
			@last_row_id		int,
			@replen_group		int,
			@last_replen_group	int,
			@from_group			varchar(20),
			@to_group			varchar(20),
			@location			varchar(10),
			@queue_id			int,
			@replen_type		varchar(50),
			@part_no			varchar(30),
			@part_desc			varchar(255),
			@from_bin			varchar(20),
			@to_bin				varchar(20),
			@qty				decimal(20,8),
			@first				int,
			@item_count			int,
			@page_no			int,
			@order_by_str		varchar(50)
   
	-- Create temp table to hold results
	CREATE TABLE #selected(
		rec_key INT IDENTITY (1,1),
		bin_no	VARCHAR(12),
		part_no VARCHAR(30),
		part_desc VARCHAR(255) NULL)

	-- Clear out temp tables sent in from PC Client  
	DELETE FROM #cvo_replen_label  
	DELETE FROM #PrintData_Output  
  
	-- Get lable details  
	SET @format_id = NULL

	SELECT	@format_id = format_id
	FROM	tdc_tx_print_detail_config (NOLOCK)
	WHERE	Trans_Source = 'VB' 
	AND		Module = 'ADH' 
	AND		Trans = 'REPLENLAB'

	IF @format_id IS NULL
	BEGIN
		RAISERROR ('No Label Defined', 16, 1)    
		RETURN -1
	END
		
	EXEC @return_value = cvo_print_label_sp 'ADH', 'REPLENLAB', 'VB', @station_id, @format_id      
      
	-- IF label hasn't been set up for the station id, try finding a record for the user id      
	IF @return_value != 0      
	BEGIN      
		EXEC @return_value = cvo_print_label_sp 'ADH', 'REPLENLAB', 'VB', @user_id, @format_id      
	END      
       
	-- IF label hasn't been set up for the user id, exit      
	IF @return_value <> 0      
	BEGIN   
		RETURN
	END  
  
	SELECT	TOP 1 @number_of_copies = number_of_copies,  
			@printer_id = printer_id  
	FROM	#PrintData_Output  
  
	-- Get maximum number of pages  
	SELECT	@max_details_on_page = detail_lines  
	FROM	dbo.tdc_tx_print_detail_config (NOLOCK)      
	WHERE   module = 'ADH'       
	AND		trans = 'REPLENLAB'    
	AND		trans_source = 'VB'    
	AND		format_id = @format_id
  
	-- If not defined, get default from config  
	IF ISNULL(@max_details_on_page, 0) = 0    
	BEGIN    
		SELECT @max_details_on_page = 11  
	END   

	-- prepare data for printing
	CREATE TABLE #cvo_replenishment_temp (
		replen_group    int, 
        location        varchar(10),
        queue_id        int,
        part_no         varchar(30),
        part_desc       varchar(255),
        from_bin        varchar(20),
        to_bin          varchar(20),
        qty				decimal(20,8))

	INSERT	#cvo_replenishment_temp
	SELECT	replen_group,location, queue_id, part_no, part_desc, from_bin, to_bin, qty
	FROM	#cvo_replenishment

	DELETE	#cvo_replenishment

	-- Insert data in replen_group based on the order by
	IF (@order_by = 0)
	BEGIN
		SET @order_by_str = 'From Bin Order'
		INSERT	#cvo_replenishment (replen_group,location, queue_id, part_no, part_desc, from_bin, to_bin, qty)
		SELECT	replen_group,location, queue_id, part_no, part_desc, from_bin, to_bin, qty
		FROM	#cvo_replenishment_temp
		ORDER BY replen_group, from_bin
	END
	ELSE
	BEGIN
		SET @order_by_str = 'To Bin Order'
		-- Insert data in replen_group, to_bin order
		INSERT	#cvo_replenishment (replen_group,location, queue_id, part_no, part_desc, from_bin, to_bin, qty)
		SELECT	replen_group,location, queue_id, part_no, part_desc, from_bin, to_bin, qty
		FROM	#cvo_replenishment_temp
		ORDER BY replen_group, to_bin
	END

	DROP TABLE #cvo_replenishment_temp
      
	-- Process the replenishment records
	SET @last_row_id = 0 
	SET	@last_replen_group = 0
	SET @first = 1
	SET @item_count = 0
	SET @page_no = 0

	SELECT	TOP 1 @row_id = row_id,
			@replen_group = replen_group,
			@queue_id = queue_id,
			@location = location,
			@part_no = part_no,
			@part_desc = part_desc,
			@from_bin = from_bin,
			@to_bin = to_bin,
			@qty = qty
	FROM	#cvo_replenishment
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Has the replenishment group changed
		IF (@replen_group <> @last_replen_group OR @item_count = @max_details_on_page)
		BEGIN
			-- Finish current label
			IF (@first = 0 OR @item_count = @max_details_on_page)
			BEGIN
				-- Print footer  
				INSERT INTO #cvo_replen_label (print_value) SELECT '*PRINTERNUMBER,' + @printer_id    
				INSERT INTO #cvo_replen_label (print_value) SELECT '*QUANTITY,1'    
				INSERT INTO #cvo_replen_label (print_value) SELECT '*DUPLICATES,' + RTRIM(CAST(@number_of_copies AS char(4)))    
				INSERT INTO #cvo_replen_label (print_value) SELECT '*PRINTLABEL'    
				SET @page_no = @page_no + 1
			END
			SET @first = 0			

			IF (@replen_group <> @last_replen_group OR @item_count = @max_details_on_page) 
			BEGIN
				IF (@replen_group <> @last_replen_group)
				BEGIN
					SET @last_replen_group = @replen_group
					SET @page_no = 1
				END

				-- New page  
				INSERT INTO #cvo_replen_label (print_value) SELECT '*FORMAT,' + @format_id    
				SET @item_count = 0  

				SELECT	@replen_type = replen_group,
						@from_group = from_bin_group,
						@to_group = to_bin_group
				FROM	replenishment_groups (NOLOCK)
				WHERE	replen_id = @replen_group			

				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_REPLENGRP,' + @replen_type    
				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_FROMGRP,' + @from_group    
				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_TOGRP,' + @to_group    
				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_LOCATION,' + @location    
				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_PAGE,' + CAST(@page_no as varchar(10))
				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_ORDER,' + @order_by_str    
				INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_CREATED_BY,' + @user_id    
			END
		END

		SET @item_count = @item_count + 1

		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_QTRANID_' + CAST(@item_count AS varchar(10)) + ',' + CAST(@queue_id AS varchar(10))    
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_PARTNO_' + CAST(@item_count AS varchar(10)) + ',' + @part_no
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_PARTDESC_' + CAST(@item_count AS varchar(10)) + ',' + @part_desc
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_FROMBIN_' + CAST(@item_count AS varchar(10)) + ',' + @from_bin		
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_TOBIN_' + CAST(@item_count AS varchar(10)) + ',' + @to_bin		
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_QTY_' + CAST(@item_count AS varchar(10)) + ',' + CAST(CAST(@qty AS int) AS varchar(10)) 			

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@replen_group = replen_group,
				@queue_id = queue_id,
				@location = location,
				@part_no = part_no,
				@part_desc = part_desc,
				@from_bin = from_bin,
				@to_bin = to_bin,
				@qty = qty
		FROM	#cvo_replenishment
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END
 
	WHILE (@item_count < @max_details_on_page)
	BEGIN

		SET @item_count = @item_count + 1

		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_QTRANID_' + CAST(@item_count AS varchar(10)) + ','
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_PARTNO_' + CAST(@item_count AS varchar(10)) + ','
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_PARTDESC_' + CAST(@item_count AS varchar(10)) + ','
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_FROMBIN_' + CAST(@item_count AS varchar(10)) + ','
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_TOBIN_' + CAST(@item_count AS varchar(10)) + ','
		INSERT INTO #cvo_replen_label (print_value) SELECT 'LP_QTY_' + CAST(@item_count AS varchar(10)) + ','

	END

	-- Print footer  
	INSERT INTO #cvo_replen_label (print_value) SELECT '*PRINTERNUMBER,' + @printer_id    
	INSERT INTO #cvo_replen_label (print_value) SELECT '*QUANTITY,1'    
	INSERT INTO #cvo_replen_label (print_value) SELECT '*DUPLICATES,' + RTRIM(CAST(@number_of_copies AS char(4)))    
	INSERT INTO #cvo_replen_label (print_value) SELECT '*PRINTLABEL'    

	-- Load into static table  
	DELETE FROM cvo_replen_label WHERE [user_id] = @user_ID  
	INSERT INTO cvo_replen_label SELECT print_value, @user_id FROM #cvo_replen_label  
  
	--Create the file  
	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'  
	SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name()   
	SET @xp_cmdshell = @xp_cmdshell + '.dbo.cvo_replen_label (NOLOCK) WHERE [user_id] = ' + '''' + @user_id + '''' + ' order by row_id" -s"," -h -1 -W -b -o  "'   
	SET @xp_cmdshell = @xp_cmdshell + @lwlPath  + '\REPL-' + CAST(newid()AS VARCHAR(60)) + '.pas"'     
    
	EXEC master..xp_cmdshell  @xp_cmdshell, no_output  
	IF @@ERROR <> 0  
	BEGIN  
		RAISERROR ('Label Print Failed', 16, 1)    
		RETURN -1
	END  

	RETURN 0
END     
    
GO
GRANT EXECUTE ON  [dbo].[cvo_replenish_print_sp] TO [public]
GO
