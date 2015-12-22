SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_print_custom_frame_putaway_sp]	@userid		varchar(50),
													@station_id	varchar(20),
													@order_no	int,
													@order_ext	int,
													@line_no	int,
													@location	varchar(10)
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@xp_cmdshell		varchar(1000),
			@lwlPath			varchar (100),
			@tran_id			int,
			@part_no			varchar(30),
			@part_desc			varchar(255),
			@from_bin			varchar(20),
			@to_bin				varchar(20),
			@quantity			decimal(20,8),
			@line_count			int,
			@ord_plus_ext       varchar(20),
			@id					int,
			@last_id			int,
			@format_id          varchar(40),   
			@printer_id         varchar(30), 
			@number_of_copies   int,
			@return_value		int

	-- Initialize
	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'

	-- Create working tables
	IF (object_id('tempdb..#cf_putaway') IS NOT NULL) 
		DROP TABLE #cf_putaway   

	IF (object_id('tempdb..#PrintData_Output') IS NOT NULL) 
		DROP TABLE #PrintData_Output   

	IF (object_id('tempdb..#PrintData') IS NOT NULL) 
		DROP TABLE #PrintData 

	IF (object_id('tempdb..#Select_Result') IS NOT NULL) 
		DROP TABLE #Select_Result      

	IF (object_id('tempdb..#PrintData_detail') IS NOT NULL) 
		DROP TABLE #PrintData_detail

	CREATE TABLE #cf_putaway (
		id				int IDENTITY(1,1),
		tran_id			int,
		part_no			varchar(30),
		part_desc		varchar(255),
		from_bin		varchar(20),
		to_bin			varchar(20),
		quantity		decimal(20,8))
		
	CREATE TABLE #PrintData_Output (
		format_id        varchar(40) NOT NULL,    
		printer_id       varchar(30) NOT NULL,    
		number_of_copies int         NOT NULL)

	CREATE TABLE #PrintData (
		data_field		varchar(300) NOT NULL,    
		data_value		varchar(300) NULL)

	CREATE TABLE #tdc_print_ticket (  
		row_id			int identity (1,1) NOT NULL,    
		print_value		varchar(300) NOT NULL)

	CREATE TABLE #Select_Result (
		data_field		varchar(300) NOT NULL,    
		data_value		varchar(300) NULL)

	-- Get the required data
	INSERT	#cf_putaway (tran_id, part_no, part_desc, from_bin, to_bin, quantity)
	SELECT	a.tran_id, a.part_no, b.description, a.bin_no, a.next_op, a.qty_to_process
	FROM	tdc_pick_queue a (NOLOCK)
	JOIN	inv_master b (NOLOCK) 
	ON		a.part_no = b.part_no
	WHERE	a.trans_type_no = @order_no
	AND		a.trans_type_ext = @order_ext
	AND		a.line_no = @line_no
	ORDER BY a.tran_id ASC

	-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----  
	EXEC @return_value = tdc_print_label_sp 'QTX', 'QCFPAWAY', 'CO', @station_id  
  
	-- IF label hasn't been set up for the station id, try finding a record for the user id  
	IF @return_value != 0  
	BEGIN  
		EXEC @return_value = tdc_print_label_sp 'QTX', 'QCFPAWAY', 'CO', @userid  
	END  
  
	-- IF label hasn't been set up for the user id, exit  
	IF @return_value <> 0  
	BEGIN  
		TRUNCATE TABLE #PrintData  
		RETURN  
	END  

	SELECT	@format_id = format_id, 
			@printer_id = printer_id, 
			@number_of_copies = number_of_copies 
	FROM	#PrintData_Output  


	-- Insert the header info for the label
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   	

	SET	@ord_plus_ext = CAST(@order_no  AS varchar(10)) + '-' + CAST(@order_ext AS varchar(4))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT', ISNULL(@ord_plus_ext, ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LINE_NO', CAST(@line_no AS varchar(6)))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION', @location)  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID', @userid)  

	-- Get the details
	SET	@last_id = 0
	SET @line_count = 1

	SELECT	TOP 1 @id = id,
			@tran_id = tran_id,
			@part_no = part_no,
			@part_desc = part_desc,
			@from_bin = from_bin,
			@to_bin = to_bin,
			@quantity = quantity	
	FROM	#cf_putaway
	WHERE	id > @last_id
	ORDER BY id

	WHILE @@ROWCOUNT <> 0
	BEGIN

		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRAN_ID_' + CAST(@line_count AS varchar(1)), CAST(@tran_id AS varchar(10)))  		
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PART_NO_' + CAST(@line_count AS varchar(1)), @part_no)  		
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DESCRIPTION_' + CAST(@line_count AS varchar(1)), @part_desc)  		
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FROM_BIN_' + CAST(@line_count AS varchar(1)), @from_bin)  		
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_BIN_' + CAST(@line_count AS varchar(1)), @to_bin)  		
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_QUANTITY_' + CAST(@line_count AS varchar(1)), CAST(CAST(@quantity as int) AS varchar(10)))  		

		SET @line_count = @line_count + 1
		SET	@last_id = @id

		SELECT	TOP 1 @id = id,
				@tran_id = tran_id,
				@part_no = part_no,
				@part_desc = part_desc,
				@from_bin = from_bin,
				@to_bin = to_bin,
				@quantity = quantity	
		FROM	#cf_putaway
		WHERE	id > @last_id
		ORDER BY id
	END

	-- Move data in table for print routine
	INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  

	INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,1'  
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,1'  
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,1'
	INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  

	-- Move the print data into a permanent table so it can be access by the xp_cmdshell
	DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID
	INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket
	DELETE FROM #tdc_print_ticket

	--Create the file
	SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\CFP-' + CAST(newid()AS VARCHAR(60)) + '.pas"'   
				
	EXEC master..xp_cmdshell  @xp_cmdshell, no_output


END
GO
GRANT EXECUTE ON  [dbo].[cvo_print_custom_frame_putaway_sp] TO [public]
GO
