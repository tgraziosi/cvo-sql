SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 11/10/2013 - Issue #1396 - if this routine was called from the BackOrder Processing routine, then get print setting based on BACKORDER as opposed to 999
-- v1.2 CB 10/09/2015 - Issue #1552 - Add insert to tdc log

CREATE PROC [dbo].[cvo_print_xfer_pick_ticket_sp]	@xfer_no int, 
												@isbackorder SMALLINT = 0 -- v1.1
AS  
BEGIN  
  
	-- Directives  
	SET NOCOUNT ON  

	-- Declarations  
	DECLARE @in_where_clause varchar(255),  
			@location   varchar(10),  
			@xp_cmdshell  varchar(1000),  
			@lwlPath   varchar (100),
			@msg varchar(100) -- v1.2  
  
	-- Initialize  
	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'  

	-- Temp tables
	IF (OBJECT_ID('tempdb..#pick_ticket_details') IS NOT NULL)
		DROP TABLE #pick_ticket_details
	IF (object_id('tempdb..#tdc_print_ticket') IS NOT NULL) 
		DROP TABLE #tdc_print_ticket   
	IF (object_id('tempdb..#PrintData_Output') IS NOT NULL) 
		DROP TABLE #PrintData_Output   
	IF (object_id('tempdb..#PrintData')        IS NOT NULL) 
		DROP TABLE #PrintData          
	IF (object_id('tempdb..#Select_Result')    IS NOT NULL) 
		DROP TABLE #Select_Result      
	IF (object_id('tempdb..#PrintData_detail') IS NOT NULL) 
		DROP TABLE #PrintData_detail

	-- Create temp tables
	CREATE TABLE #pick_ticket_details(                                                                             
		xfer_no			int NOT NULL,                      
		[status]		char(1) NOT NULL,                      
		to_loc			varchar(10) NOT NULL,                      
		from_loc		varchar(10) NOT NULL,                      
		sch_ship_date   datetime NULL,                      
		curr_alloc_pct  decimal(15,2) NULL,                      
		sel_flg         int NOT NULL DEFAULT 0)
	
	CREATE TABLE #PrintData_Output(                
		format_id        varchar(40)  NOT NULL,   
		printer_id       varchar(30)  NOT NULL,    
		number_of_copies int          NOT NULL)

	CREATE TABLE #PrintData(                 
		data_field		varchar(300) NOT NULL,    
		data_value		varchar(300)     NULL)

	CREATE TABLE #tdc_print_ticket(                  
		row_id			int identity (1,1)  NOT NULL,    
		print_value		varchar(300)        NOT NULL)

	CREATE TABLE #Select_Result(    
		data_field		varchar(300) NOT NULL,    
		data_value		varchar(300)     NULL)

	CREATE TABLE #PrintData_detail(                         
		row_id          INT          NOT NULL IDENTITY(1,1),    
		order_no        INT          NOT NULL,                  
		order_ext       INT          NOT NULL,                  
		carton_no       INT          NOT NULL,                  
		part_no_desc    VARCHAR(50)  NOT NULL,                  
		type_code       VARCHAR(10)  NOT NULL,                 
		add_case        CHAR(1)      NOT NULL,                  
		cases_included  VARCHAR(15)      NULL,                  
		from_line_no    INT          NOT NULL,                  
		line_no         INT          NOT NULL,                  
		material        VARCHAR(15)  NOT NULL,                  
		origin          VARCHAR(40)  NOT NULL,                  
		qty             VARCHAR(40)  NOT NULL,                  
		unit_value      DECIMAL(20,8)    NULL,                  
		total_value     DECIMAL(20,8)    NULL,                  
		schedule_B_no   VARCHAR(40)      NULL)              

	-- Load xfer detail in
	INSERT INTO #pick_ticket_details (
		xfer_no, 
		[status], 
		from_loc, 
		to_loc, 
		sch_ship_date, 
		curr_alloc_pct, 
		sel_flg)
	SELECT 
		xfer_no, 
		[status], 
		from_loc, 
		to_loc, 
		sch_ship_date, 
		0, 
		1  
	FROM 
		dbo.xfers (NOLOCK) 
	WHERE 
		xfer_no  = @xfer_no
				   
	-- Call print routine
	-- START v1.1
	IF ISNULL(@isbackorder,0) = 0
	BEGIN
		EXEC tdc_print_plw_xfer_pick_ticket_sp 'AUTO_ALLOC', '999', @xfer_no
	END
	ELSE
	BEGIN
		EXEC tdc_print_plw_xfer_pick_ticket_sp 'AUTO_ALLOC', 'BACKORDER', @xfer_no
	END
	-- END v1.1

	IF EXISTS(SELECT 1 FROM #PrintData_Output)
	BEGIN
		UPDATE #tdc_print_ticket SET print_value = REPLACE('*DUPLICATES,-1','-1','1') WHERE print_value = '*DUPLICATES,-1'

		-- Create the label
		-- Move the print data into a permanent table so it can be access by the xp_cmdshell  
		DELETE FROM CVO_tdc_xfer_print_ticket WHERE process_id = @@SPID  
		INSERT CVO_tdc_xfer_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket  
		DELETE FROM #tdc_print_ticket  

		--Create the file  
		SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_xfer_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\XPTK-' + CAST(newid()AS VARCHAR(60)) + '.pas"'     
		  
		EXEC master..xp_cmdshell  @xp_cmdshell, no_output  

		IF @@Error <> 0  
			RETURN  

		UPDATE 
			dbo.xfers                                                  
		SET 
			[status] = 'Q', 
			printed = 'Q',                   
			date_printed = GETDATE()  
		WHERE
			xfer_no = @xfer_no

		-- v1.2 Start
		SELECT	@msg = 'STATUS:Q; FROM:' + from_loc + '; TO:' + to_loc + '',
				@location = from_loc
		FROM	dbo.xfers (NOLOCK) 
		WHERE 	xfer_no  = @xfer_no

		INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
		SELECT GETDATE(),'BACKORDER','BO','ADM','XFER PICK TICKET', CAST(@xfer_no as varchar(20)), '0', '', '', '', @location, '', @msg
		-- v1.2 End

	END
END

GO
GRANT EXECUTE ON  [dbo].[cvo_print_xfer_pick_ticket_sp] TO [public]
GO
