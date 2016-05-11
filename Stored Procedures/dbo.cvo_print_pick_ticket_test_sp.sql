SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_print_pick_ticket_test_sp] @order_no	int,
										 @order_ext	int, 
										 @isbackorder SMALLINT = 0 -- v1.2
AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@in_where_clause	varchar(255),
			@location			varchar(10),
			@xp_cmdshell		varchar(1000),
			@lwlPath			varchar (100)

	-- Initialize
	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'

	-- Create working tables
	IF OBJECT_ID('tempdb..#so_pick_ticket') IS NULL -- v1.1
	BEGIN
		CREATE TABLE #so_pick_ticket (
				cons_no			int NULL,
				order_no		int NULL,
				order_ext       int NULL,
				location        varchar (10) NOT NULL,
				line_no         int NULL,  
				part_no         varchar(30) NOT NULL, 
				lot_ser         varchar(25) NULL, 
				bin_no          varchar(12) NULL, 
				ord_qty         decimal(20,8) NOT NULL, 
				pick_qty        decimal(20,8) NOT NULL,
				part_type       char(1) NULL,
				[user_id]       varchar(50) NOT NULL, 
				order_date      datetime NULL, 
				cust_po         varchar(20) NULL,  
				sch_ship_date   datetime NULL, 
				carrier_desc    varchar(40) NULL,
				ship_to_add_1   varchar(40) NULL,
				ship_to_add_2   varchar(40) NULL,
				ship_to_add_3   varchar(40) NULL,
				ship_to_city    varchar(40) NULL, 
				ship_to_country varchar(40) NULL,
				ship_to_name    varchar(40) NULL,
				ship_to_state   char(40) NULL,
				ship_to_zip     varchar(10) NULL, 
				special_instr   varchar(255) NULL, 
				order_note      varchar(255) NULL,
				item_note       varchar(255) NULL,
				uom             char(2) NULL,
				[description]   varchar(255) NULL, 
				customer_name   varchar(40) NULL,
				addr1           varchar(40) NULL,
				addr2           varchar(40) NULL, 
				addr3           varchar(40) NULL, 
				addr4           varchar(40) NULL, 
				addr5           varchar(40) NULL,
				cust_code       varchar(10) NULL, 
				kit_caption     varchar(255) NULL, 
				cancel_date     datetime NULL, 
				kit_id          varchar(30) NULL, 
				group_code_id   varchar (20) NULL,
				seq_no          int NULL, 
				tran_id         int NULL, 
				dest_bin        varchar(12) NULL,
				trans_type      varchar(10) NOT NULL, 
				date_expires    datetime NULL)      
	END

	IF OBJECT_ID('tempdb..#so_pick_ticket_working_tbl') IS NULL -- v1.1
	BEGIN
		CREATE TABLE #so_pick_ticket_working_tbl (
		order_no        int not null,
		order_ext       int not null, 
		line_no         int not null, 
		[description]   varchar(255) null, 
		part_no         varchar(50) not null, 
		part_type       char(1) not null)      
	END

	IF OBJECT_ID('tempdb..#so_pick_ticket_details') IS NULL -- v1.1
	BEGIN
		CREATE TABLE #so_pick_ticket_details (
				order_no				int NULL,
				order_ext				int NULL,
				con_no					int NOT NULL,
				status					char(1) NOT NULL, 
				location				varchar(10) NULL,
				sch_ship_date			datetime NULL,
				cust_name				varchar(255) NULL,
				curr_alloc_pct			decimal(20,2) NULL, 
				sel_flg					int NOT NULL,
				alloc_type				varchar(2) NULL,
				total_pieces			int NULL, 
				lowest_bin_no			varchar(12) NULL,
				highest_bin_no			varchar(12) NULL,
				cust_code				varchar(10) NULL,
				consolidate_shipment	int NOT NULL,
				promo_id				varchar(20) NULL,
				promo_level				varchar(20) NULL) -- v1.8  
	END

    IF (OBJECT_ID('tempdb..#temp_who') IS NULL) -- v1.1
	BEGIN
		CREATE TABLE #temp_who (
				who			varchar(50),
				login_id	varchar(50))
	END

	-- Insert default data
	INSERT INTO #so_pick_ticket_details (con_no, status, location, sel_flg, cust_name, consolidate_shipment, promo_id) 
	VALUES (0, 'N', 'NONE', 0, '[Adhoc]',0, '')

	INSERT #temp_who SELECT 'AUTO_ALLOC','AUTO_ALLOC'

	-- Build the where clause
	SET @in_where_clause = ' AND orders.order_no = ' + CAST(@order_no AS varchar(12)) + ' AND orders.ext = ' + CAST(@order_ext AS varchar(12)) + ' '
	-- Call Data Selection Routine	
	EXEC tdc_plw_so_print_selection_test__sp 0,' AND orders.cust_code = CVO_armaster_all.customer_code and CVO_armaster_all.address_type NOT IN (9,1) AND orders.status IN(''N'',''P'',''Q'') ', @in_where_clause, '', ''

	-- Test that we have some data to process
	IF NOT EXISTS(SELECT 1 FROM #so_pick_ticket_details) 
		RETURN

	-- Update the temp table to mark the record to print
	UPDATE #so_pick_ticket_details SET sel_flg = 1

	select 'printing'
	select * from #so_pick_ticket_details WHERE order_no = 2798568 



	-- Call standard routine to populate the print data
	EXEC tdc_plw_so_print_assign_test_sp 'AUTO_ALLOC'

	select 'print2'
select * from #so_pick_ticket WHERE order_no = 2798568


	-- Reorganized sort order
	EXEC CVO_pick_list_print_by_lowest_bin_no_sp

	-- Create working table for printing
	IF (object_id('tempdb..#tdc_print_ticket') IS NULL) -- v1.1
	BEGIN
		CREATE TABLE #tdc_print_ticket (  
			row_id			int identity (1,1) NOT NULL,    
			print_value		varchar(300) NOT NULL) 
	END

	IF (object_id('tempdb..#PrintData_Output') IS NULL) -- v1.1
	BEGIN
		CREATE TABLE #PrintData_Output (
			format_id        varchar(40) NOT NULL,    
			printer_id       varchar(30) NOT NULL,    
			number_of_copies int         NOT NULL)  
	END

	IF (object_id('tempdb..#PrintData') IS NULL) -- v1.1
	BEGIN
		CREATE TABLE #PrintData (
			data_field		varchar(300) NOT NULL,    
			data_value		varchar(300) NULL)
	END

	IF (object_id('tempdb..#Select_Result') IS NULL) -- v1.1
	BEGIN
		CREATE TABLE #Select_Result (
			data_field		varchar(300) NOT NULL,    
			data_value		varchar(300) NULL)    
	END

	IF (object_id('tempdb..#PrintData_detail') IS NULL) -- v1.1
	BEGIN
		CREATE TABLE #PrintData_detail (
			row_id          INT NOT NULL IDENTITY(1,1),    
			order_no        INT NOT NULL,
			order_ext       INT NOT NULL,
			carton_no       INT NOT NULL, 
			part_no_desc    VARCHAR(50) NOT NULL,
			type_code       VARCHAR(10) NOT NULL,
			add_case        CHAR(1) NOT NULL,
			cases_included  VARCHAR(15) NULL, 
			from_line_no    INT NOT NULL, 
			line_no         INT NOT NULL, 
			material        VARCHAR(15) NOT NULL,
			origin          VARCHAR(40) NOT NULL,
			qty             VARCHAR(40) NOT NULL,
			unit_value      DECIMAL(20,8) NULL, 
			total_value     DECIMAL(20,8) NULL,
			schedule_B_no   VARCHAR(40) NULL)              
	END

	-- Get Location
	SELECT	@location = location
	FROM	#so_pick_ticket    

	DELETE	#PrintData -- v1.4

	-- Call pick ticket print
	-- START v1.2
	IF ISNULL(@isbackorder,0) = 0 
	BEGIN
		EXEC [tdc_print_plw_so_pick_ticket_test_sp] 'AUTO_ALLOC', 'CUSTOM', @order_no, @order_ext, @location
	END
	ELSE
	BEGIN
		EXEC [tdc_print_plw_so_pick_ticket_test_sp] 'AUTO_ALLOC', 'BACKORDER', @order_no, @order_ext, @location
	END
	-- END v1.2

	if(@order_no = 2798568)
	select * from #tdc_print_ticket

	return

	-- Move the print data into a permanent table so it can be access by the xp_cmdshell
	DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID
	-- START v1.3
	INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket ORDER BY row_id 
	--INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket
	-- END v1.3
	DELETE FROM #tdc_print_ticket

	--Create the file
	SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\PTK-' + CAST(newid()AS VARCHAR(60)) + '.pas"'   
				
	EXEC master..xp_cmdshell  @xp_cmdshell, no_output

	IF @@Error <> 0
		RETURN

	UPDATE	orders_all
	SET		status = 'Q',
			printed = 'Q',
			date_printed = GETDATE() -- v1.5
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	-- v1.5 Start
	INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
	SELECT GETDATE(),'BACKORDER','BO','ADM','PICK TICKET', CAST(@order_no as varchar(20)), CAST(@order_ext as varchar(10)), '', '', '', @location, '', 'STATUS:Q; HOLDREASON:'
	-- v1.5 End

	-- v1.6 Start
	EXEC dbo.cvo_update_bo_processing_sp 'P', @order_no, @order_ext
	-- v1.6 End

END
GO
GRANT EXECUTE ON  [dbo].[cvo_print_pick_ticket_test_sp] TO [public]
GO
