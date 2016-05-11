SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

*/

-- v1.0 CT 02/04/2014 - Issue #572 - Masterpack print pick ticket for consolided order
-- v1.1 CB 17/08/2015 - Not picking up consolidated orders correctly
-- v1.2 CB 15/04/2016 - #1596 - Add promo level

  
CREATE PROC [dbo].[cvo_print_consolidated_pick_ticket_sp]	@consolidation_no int,  
														@isbackorder SMALLINT = 0 
AS  
BEGIN  
  
	-- Directives  
	SET NOCOUNT ON  
  
	-- Declarations  
	DECLARE @in_where_clause varchar(255),  
			@location   varchar(10),  
			@xp_cmdshell  varchar(1000),  
			@lwlPath   varchar (100),
			@order_no	INT,
			@order_ext	INT,  
			@row_id		INT

	-- Initialize  
	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'  
  
	-- Create working tables  
	IF OBJECT_ID('tempdb..#so_pick_ticket') IS NULL 
	BEGIN  
		CREATE TABLE #so_pick_ticket (  
			cons_no   int NULL,  
			order_no  int NULL,  
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
 
	IF OBJECT_ID('tempdb..#so_pick_ticket_working_tbl') IS NULL 
	BEGIN  
		CREATE TABLE #so_pick_ticket_working_tbl (  
			order_no        int not null,  
			order_ext       int not null,   
			line_no         int not null,   
			[description]   varchar(255) null,   
			part_no         varchar(50) not null,   
			part_type       char(1) not null)        
	END  
  
	IF OBJECT_ID('tempdb..#so_pick_ticket_details') IS NULL 
	BEGIN  
		CREATE TABLE #so_pick_ticket_details (  
			order_no    int NULL,  
			order_ext    int NULL,  
			con_no     int NOT NULL,  
			status     char(1) NOT NULL,   
			location    varchar(10) NULL,  
			sch_ship_date   datetime NULL,  
			cust_name    varchar(255) NULL,  
			curr_alloc_pct   decimal(20,2) NULL,   
			sel_flg     int NOT NULL,  
			alloc_type    varchar(2) NULL,  
			total_pieces   int NULL,   
			lowest_bin_no   varchar(12) NULL,  
			highest_bin_no   varchar(12) NULL,  
			cust_code    varchar(10) NULL,  
			consolidate_shipment int NOT NULL,  
			promo_id    varchar(20) NULL,
			promo_level    varchar(20) NULL) -- v1.2
	END  

	  
	IF (OBJECT_ID('tempdb..#temp_who') IS NULL)
	BEGIN  
		CREATE TABLE #temp_who (  
			who   varchar(50),  
			login_id varchar(50))  
	END  
  
	 -- Insert default data  
	 INSERT INTO #so_pick_ticket_details (con_no, status, location, sel_flg, cust_name, consolidate_shipment, promo_id)   
	 VALUES (0, 'N', 'NONE', 0, '[Adhoc]',0, '')  
	  
	 INSERT #temp_who SELECT 'AUTO_ALLOC','AUTO_ALLOC'  
  
	-- Get first order in the list which is allocated
	SELECT TOP 1
		@order_no = a.order_no,
		@order_ext = a.order_ext
	FROM
		dbo.cvo_masterpack_consolidation_det a (NOLOCK)
	INNER JOIN
		dbo.tdc_soft_alloc_tbl b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.order_ext
	WHERE
		a.consolidation_no = @consolidation_no
		AND b.order_type = 'S'
	ORDER BY
		a.order_no, 
		a.order_ext

	IF @@ROWCOUNT = 0
		RETURN

	-- v1.1 Start
	INSERT	INTO #so_pick_ticket_details 
            (order_no, order_ext, con_no, status, location, sch_ship_date, cust_name, curr_alloc_pct, sel_flg, alloc_type, cust_code, consolidate_shipment, promo_id, promo_level) -- v1.2
	SELECT	DISTINCT a.trans_type_no, 
			a.trans_type_ext, 
			b.consolidation_no, 
			c.status,  
			a.location, 
			c.sch_ship_date, 
			c.ship_to_name, 0, 0,   
			alloc_type = (SELECT top 1 alloc_type FROM tdc_cons_ords   
							WHERE order_no  = a.trans_type_no  
							AND order_ext = a.trans_type_ext   
							AND location  = a.location), 
			c.cust_code, 0, 
			ISNULL(d.promo_id, ''),
			ISNULL(d.promo_level, '') -- v1.2
	FROM	tdc_pick_queue a (NOLOCK)
	JOIN	tdc_cons_ords b (NOLOCK)
	ON		a.trans_type_no = b.order_no  
    AND		a.trans_type_ext = b.order_ext  
	JOIN	orders c (NOLOCK)
	ON		b.order_no = c.order_no                                         
    AND		b.order_ext = c.ext  
	JOIN	armaster e (NOLOCK)
	ON		c.cust_code = e.customer_code  
    AND		c.ship_to = e.ship_to_code  
	JOIN	cvo_orders_all d(NOLOCK)
	ON		c.order_no = d.order_no
	AND		c.ext = d.ext
	JOIN	cvo_ord_list f (NOLOCK)                                       
	ON		a.trans_type_no = f.order_no                                                    
	AND		a.trans_type_ext = f.order_ext
	AND		a.line_no = f.line_no
	JOIN	cvo_masterpack_consolidation_det g(NOLOCK)
	ON		a.trans_type_no = g.order_no 
	AND		a.trans_type_ext= g.order_ext
    WHERE	a.trans IN ('STDPICK')
    AND		e.address_type = (SELECT MAX(address_type)   
								FROM armaster (NOLOCK)   
								WHERE customer_code = c.cust_code   
								AND ship_to_code = c.ship_to) 
	AND		g.consolidation_no = @consolidation_no
	

	-- Build the where clause  
--	SET @in_where_clause = ' AND orders.order_no = ' + CAST(@order_no AS varchar(12)) + ' AND orders.ext = ' + CAST(@order_ext AS varchar(12)) + ' '  
	-- Call Data Selection Routine   
--	EXEC tdc_plw_so_print_selection_sp 0,' AND orders.cust_code = CVO_armaster_all.customer_code and CVO_armaster_all.address_type NOT IN (9,1) AND orders.status IN(''N'',''P'',''Q'') ', @in_where_clause, '', ''  
  
	-- v1.1 End

	-- Test that we have some data to process  
	IF NOT EXISTS(SELECT 1 FROM #so_pick_ticket_details)   
		RETURN  
  
	-- Update the temp table to mark the record to print  
	UPDATE #so_pick_ticket_details SET sel_flg = 1  
  
	-- Call standard routine to populate the print data  
	EXEC tdc_plw_so_print_assign_sp 'AUTO_ALLOC'  
  
	-- Reorganized sort order  
	EXEC CVO_pick_list_print_by_lowest_bin_no_sp  
  
	-- Create working table for printing  
	IF (object_id('tempdb..#tdc_print_ticket') IS NULL) -- v1.1  
	BEGIN  
		CREATE TABLE #tdc_print_ticket (    
			row_id   int identity (1,1) NOT NULL,      
			print_value  varchar(300) NOT NULL)   
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
			data_field  varchar(300) NOT NULL,      
			data_value  varchar(300) NULL)  
	END  
  
	IF (object_id('tempdb..#Select_Result') IS NULL) -- v1.1  
	BEGIN  
		CREATE TABLE #Select_Result (  
			data_field  varchar(300) NOT NULL,      
			data_value  varchar(300) NULL)      
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
	 SELECT @location = location  
	 FROM #so_pick_ticket       
  
	 -- Call pick ticket print  
	 -- START v1.2  
	 IF ISNULL(@isbackorder,0) = 0   
	 BEGIN  
		EXEC cvo_print_plw_so_consolidated_pick_ticket_sp 'AUTO_ALLOC', 'CUSTOM', @order_no, @order_ext, @location, @consolidation_no  
	 END  
	 ELSE  
	 BEGIN  
		EXEC cvo_print_plw_so_consolidated_pick_ticket_sp 'AUTO_ALLOC', 'BACKORDER', @order_no, @order_ext, @location, @consolidation_no    
	 END  
	 -- END v1.2  

	-- v1.1 Start
	INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
	SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
			'STATUS:Q;'
	FROM	orders_all a (NOLOCK)
	JOIN	#so_pick_ticket_details b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	-- v1.1 End
  
	 -- Move the print data into a permanent table so it can be access by the xp_cmdshell  
	 DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID  
	 INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket  
	 DELETE FROM #tdc_print_ticket  
  
	 --Create the file  
	 SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\PTK-' + CAST(newid()AS VARCHAR(60)) + '.pas"'     
      
	EXEC master..xp_cmdshell  @xp_cmdshell, no_output  
  
	IF @@Error <> 0  
		RETURN  
  
	UPDATE 
		a
	SET  
		status = 'Q',  
		printed = 'Q'  
	FROM 
		dbo.orders_all a
	INNER JOIN
		dbo.cvo_masterpack_consolidation_det b (NOLOCK)
	ON
		a.order_no = b.order_no  
		AND a.ext = b.order_ext  
	WHERE
		b.consolidation_no = @consolidation_no
  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_print_consolidated_pick_ticket_sp] TO [public]
GO
