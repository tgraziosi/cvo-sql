SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v10.0 CB 22/06/2012 - Only print the quantity allocated
-- v10.1 CB 29/06/2012 - add process_id to CVO_tdc_print_ticket so it can be used in other routines
-- v10.2 CB 05/07/2012 - add in restriction for ec sales reporting
-- v10.3 CB 09/07/2012 - Fix rounding issues with discount
-- v10.4 CB 17/07/2012 - Only use the ec sales restriction for the export declaration
-- v10.5 CT 03/08/2012 - Print if order is only soft allocated
-- v10.6 CT 17/08/2012 - Commercial invoice should display order total on last page
-- v10.7 CT 22/08/2012 - For CARICOM invoice only print freight on last page
-- v10.8 CT 22/08/2012 - For Customs invoice only print final total on last page
-- v10.9 CB 08/02/2013 - Issue #1139 - If quantity is zero then remove items
-- v11.0 CB 23/04/2013 - Issue #1234 - Need to include packed quantites but do not double count cases
-- v11.1 CT 13/03/2014 - Issue #1461 - When calculating value for Export declaration, get value of all lines which aren't cases
-- TG 08/06/2014 - update material field in print detail from 15 to 20 characters
-- v11.2 CB 19/06/2015	Fix issue with LP_TOTAL_QTY on multiple pages for CUSTOMS INVOICE
-- v11.3 CB 21/02/2017	Deal with an item split over multiple cartons
-- v11.4 CB 09/05/2018 - Fix issue with 100% discount items not being set to $1 on export declaration
-- tag 07/11/2018 - in export declaration, don't include POP in totals

-- EXEC cvo_adm_print_international_documents_sp 1419582, 0
CREATE PROC [dbo].[cvo_adm_print_international_documents_sp]	@order_no	int,
															@order_ext	int
AS
BEGIN
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@country_code		varchar(3),
			@curr_precision		int,
			@line_count			int,
			@max_lines			int,
			@total_pages		int,
			@current_page		int,
			@format_id			varchar(40),    
			@printer_id			varchar(30),
			@number_of_copies	int,
			@xp_cmdshell		varchar(1000),
			@lwlPath			varchar(100),
			@customs_value		decimal(20,8), -- v3.0
			@commodity_sum		decimal(20,8), -- v3.0
			@order_total		decimal(20,2), -- v10.6
			@is_lastpage		SMALLINT,	-- v10.7
			@LP_TOTAL_QTY		decimal(20,2), -- v11.2
			@case				varchar(10) -- v11.2

	-- Create working tables
	IF OBJECT_ID('tempdb..#cartonsToShip') IS NOT NULL  
		DROP TABLE #cartonsToShip
        
    CREATE TABLE #cartonsToShip (
		order_no                       INT,
        order_ext                      INT,
        carton_no                      INT,
        tot_ord_freight                DECIMAL(20,8),
        tot_multi_carton_ord_freight   DECIMAL(20,8),
        master_pack                    CHAR(1),     
        commit_ok                      INT,         
        first_so_in_carton             INT) 

    IF (object_id('tempdb..#tdc_print_ticket') IS NOT NULL) 
		DROP TABLE #tdc_print_ticket

    IF (object_id('tempdb..#PrintData_Output') IS NOT NULL) 
		DROP TABLE #PrintData_Output

    IF (object_id('tempdb..#PrintData') IS NOT NULL) 
		DROP TABLE #PrintData     

    IF (object_id('tempdb..#Select_Result') IS NOT NULL) 
		DROP TABLE #Select_Result 
           
	IF (object_id('tempdb..#PrintData_detail') IS NOT NULL) 
		DROP TABLE #PrintData_detail
        
	CREATE TABLE #PrintData_Output (
		format_id        varchar(40)  NOT NULL,
        printer_id       varchar(30)  NOT NULL,
        number_of_copies int          NOT NULL)

    CREATE TABLE #PrintData (
		data_field varchar(300) NOT NULL,
		data_value varchar(300)     NULL)
  
    CREATE TABLE #tdc_print_ticket (
        row_id      int identity (1,1)  NOT NULL,
        print_value varchar(300)        NOT NULL)

    CREATE TABLE #Select_Result (
        data_field varchar(300) NOT NULL,
        data_value varchar(300)     NULL)
    
    CREATE TABLE #PrintData_detail (
        row_id          INT          NOT NULL IDENTITY(1,1),
        order_no        INT          NOT NULL,              
        order_ext       INT          NOT NULL,              
        carton_no       INT          NOT NULL,   
		part_no			VARCHAR(32)	 NOT NULL,					--v2.0           
        part_no_desc    VARCHAR(50)  NOT NULL,              
        type_code       VARCHAR(10)  NOT NULL,              
        add_case        CHAR(1)      NOT NULL,              
        cases_included  VARCHAR(15)      NULL,             
        from_line_no    INT          NOT NULL,             
        line_no         INT          NOT NULL,             
        -- material        VARCHAR(15)  NOT NULL,             
		material        VARCHAR(20)  NOT NULL,  -- tag - 080614 - need to allow 20 characters           
        origin          VARCHAR(40)  NOT NULL,            
        qty             VARCHAR(40)  NOT NULL,            
        unit_value      DECIMAL(20,8)    NULL,            
        total_value     DECIMAL(20,8)    NULL,              
        schedule_B_no   VARCHAR(40)      NULL,
		weight			decimal(20,8)	 NULL)  
		

	-- START v11.1
	-- Create table to hold all lines from the order
	CREATE TABLE #Order_value (
        row_id          INT          NOT NULL IDENTITY(1,1),
        order_no        INT          NOT NULL,              
        order_ext       INT          NOT NULL,              
        part_no			VARCHAR(32)	 NOT NULL,					--v2.0           
        type_code       VARCHAR(10)  NOT NULL,                      
        line_no         INT          NOT NULL,                  
        qty             VARCHAR(40)  NOT NULL,            
        unit_value      DECIMAL(20,8)    NULL,            
        total_value     DECIMAL(20,8)    NULL,             
		weight			decimal(20,8)	 NULL)                  
	-- END v11.1

    CREATE TABLE #Print_Doc_Total (Doc_total DECIMAL(20,8) NULL)              

    DELETE #PrintData_detail  	
	DELETE #Print_Doc_Total  	
	
	SELECT	@curr_precision  = curr_precision
	FROM	glcurr_vw a (NOLOCK)
	JOIN	orders o (NOLOCK)
	ON		a.currency_code = o.curr_key
	WHERE	o.order_no = @order_no
	AND		o.ext = @order_ext

	-- This gets the carton info and/or the order depending on whether the order has been packed or not
	INSERT INTO #cartonsToShip (carton_no, order_no, order_ext, tot_ord_freight, master_pack, commit_ok, first_so_in_carton)
	SELECT	DISTINCT ISNULL(dt.carton_no,0), 
			CASE WHEN dt.order_no IS NULL THEN o.order_no ELSE dt.order_no END, 
			CASE WHEN dt.order_ext IS NULL THEN o.ext ELSE dt.order_ext END, 
			o.freight, 
			CASE WHEN s.master_pack IS NULL THEN 'N' ELSE s.master_pack END, 
			0, 
			0
	FROM	orders o (NOLOCK)
	LEFT JOIN	
			tdc_soft_alloc_tbl t (NOLOCK) -- v3.0 Only when allocated or packed.
	ON		o.order_no = t.order_no
	AND		o.ext = t.order_ext
	-- START v10.5
	LEFT JOIN	
			cvo_soft_alloc_det d (NOLOCK) 
	ON		o.order_no = d.order_no
	AND		o.ext = d.order_ext
	-- END v10.5
	LEFT JOIN
			tdc_carton_tx c (NOLOCK)
	ON		o.order_no = c.order_no
	AND		o.ext = c.order_ext
	LEFT JOIN	
			tdc_carton_detail_tx dt (NOLOCK)
	ON		c.carton_no	= dt.carton_no	
	AND		c.order_no = dt.order_no
	AND		c.order_ext = dt.order_ext
	LEFT JOIN	
			tdc_stage_carton s (NOLOCK)     
	ON		s.carton_no	= c.carton_no
	AND		s.carton_no	= dt.carton_no
	WHERE	ISNULL(c.order_type,'S') = 'S'
	AND		ISNULL(s.adm_ship_flag,'N') = 'N'
	AND		o.status IN('P', 'Q', 'N', 'R')	
	AND	NOT	(t.order_no IS NULL AND c.order_no IS NULL AND d.order_no IS NULL) -- v3.0 Only when allocated or packed. -- v10.5 include soft allocated
	AND		o.order_no = @order_no
	AND		o.ext = @order_ext	

    SELECT	@country_code = ship_to_country_cd 
	FROM	orders (NOLOCK) 
	WHERE	order_no = @order_no 
	AND		ext = @order_ext

	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'


-- If non US then print commercial and custom documents
IF (@country_code <> 'US' AND @country_code <> '')
	BEGIN


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Commercial Invoice
--	Module = 'SHP' / trans = 'PNTCOMMERCIAL'	
--
	DELETE #PrintData_detail

		-- Insert the print data	
		INSERT INTO #PrintData_detail (order_no, order_ext, carton_no, part_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value, schedule_B_no)
		SELECT	DISTINCT
				ol.order_no	AS order_no,
				ol.order_ext AS order_ext,
				ISNULL(cd.carton_no,0) AS Box, 
				ol.part_no AS part_no, 
				LEFT(ol.description,50) AS Description, 
				inv.type_code AS type_code,
				cvo.add_case AS add_case,
				cvo.line_no	AS line_no,
				cvo.from_line_no AS from_line_no,
				ISNULL( inv_add.field_10,'') AS Material, 
				ISNULL(gl.description,'') AS Origin, 
				CASE WHEN ol.shipped = 0 THEN ol.ordered ELSE ol.shipped END AS Qty,
				curr_price = CASE WHEN ol.shipped = 0 THEN  
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				ELSE
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				END,
				CASE WHEN ol.shipped = 0 THEN
					ol.ordered * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				ELSE
					ol.shipped * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				END AS Total_Value,
				ISNULL(com.cmdty_desc_1,'') AS schedule_B_no				-- v2.0
				-- ISNULL(inv.cmdty_code,'') AS schedule_B_no			-- v2.0
		FROM	ord_list ol (NOLOCK)
		JOIN	CVO_ord_list cvo (NOLOCK)
		ON		ol.order_no	= cvo.order_no		
		AND		ol.order_ext = cvo.order_ext		
		AND		ol.line_no = cvo.line_no	
		JOIN	inv_master inv (NOLOCK)
		ON		ol.part_no = inv.part_no
		JOIN	inv_master_add inv_add (NOLOCK)
		ON		ol.part_no = inv_add.part_no
		LEFT JOIN	gl_cmdty com (NOLOCK)							-- v2.0 -- v10.4
		ON		inv.cmdty_code = com.cmdty_code					-- v2.0
		JOIN	gl_country gl (NOLOCK)
		ON		inv.country_code = gl.country_code
		LEFT JOIN
				tdc_carton_detail_tx cd (NOLOCK)
		ON		ol.order_no	= cd.order_no
		AND		ol.order_ext = cd.order_ext
		AND		ol.line_no = cd.line_no
		LEFT JOIN -- v3.0 Only allocated or packed
				tdc_soft_alloc_tbl t (NOLOCK)
		ON		ol.order_no	= t.order_no
		AND		ol.order_ext = t.order_ext
		AND		ol.line_no = t.line_no
		-- START v10.5
		LEFT JOIN	
			cvo_soft_alloc_det d (NOLOCK) 
		ON		ol.order_no = d.order_no
		AND		ol.order_ext = d.order_ext
		AND		ol.line_no = d.line_no
		-- END v10.5
		WHERE	ol.order_no = @order_no
		AND		ol.order_ext = @order_ext	  
		AND	NOT	(t.order_no IS NULL AND cd.order_no IS NULL AND d.order_no IS NULL) -- v3.0 -- v10.5 - include soft allocated
-- v10.4		AND		ISNULL(com.rpt_flag_esl,0) = 1 -- v10.2

		-- START v10.5
		-- v10.0 Start - Update the quantity and values based on the allocated quantities
		/*
		UPDATE	a
		SET		qty = (SELECT SUM(qty) FROM tdc_soft_alloc_tbl b (NOLOCK) WHERE a.order_no = b.order_no
							AND a.order_ext = b.order_ext AND a.line_no = b.line_no AND a.part_no = b.part_no)
		FROM	#PrintData_detail a
		JOIN	tdc_soft_alloc_tbl c
		ON		a.order_no	= c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		*/

		UPDATE	a
		SET		qty = dbo.f_international_documents_qty (order_no, order_ext, line_no, part_no, carton_no) -- v11.3
		FROM	#PrintData_detail a
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		-- END v10.5

		UPDATE	#PrintData_detail
		SET		total_value = qty * unit_value
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		
		UPDATE	a
		SET		weight = qty * i.weight_ea
		FROM	#PrintData_detail a
		JOIN	inv_master i (NOLOCK)
		ON		a.part_no = i.part_no
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		
		-- v10.0 End

		-- v10.9
		DELETE	#PrintData_detail
		WHERE	CAST(qty AS decimal(20,8)) <= 0

		-- v11.0 Start
		IF EXISTS (SELECT 1 FROM #PrintData_detail WHERE type_code = 'CASE' AND carton_no <> 0)
		BEGIN
			DELETE	#PrintData_detail
			WHERE	type_code = 'CASE'
			AND		carton_no = 0
			AND		order_no = @order_no
			AND		order_ext = @order_ext
		END		
		-- v11. 0 End

		-- Get total lines to print
		SELECT	@line_count =  COUNT(*)+1 FROM #PrintData_detail WHERE type_code <> 'CASE'

		-- Get max detail_lines to print per page
		SET @max_lines = 0
		SELECT	@max_lines = detail_lines From tdc_tx_print_detail_config WHERE trans_source = 'VB' AND module = 'SHP' AND trans = 'PNTCOMMERCIAL'

		-- Calculate the number of pages
		IF (@line_count % @max_lines) > 0 
			SET @total_pages = CAST((@line_count / @max_lines) AS INT) + 1
		ELSE
			SET @total_pages = @line_count / @max_lines

		SELECT @format_id = ISNULL(format_id,'')
		FROM   tdc_label_format_control (NOLOCK)
		WHERE  module = 'SHP'		
		AND	   trans = 'PNTCOMMERCIAL'		
		AND    trans_source = 'VB'

		SELECT  @printer_id	= ISNULL(printer,0), 
				@number_of_copies = ISNULL(quantity,0)  
		FROM	tdc_tx_print_routing (NOLOCK)
		WHERE	module = 'SHP'		
		AND		trans = 'PNTCOMMERCIAL'		
		AND		trans_source = 'VB' 
		AND		format_id = @format_id
--		AND		user_station_id	= 999
	
		INSERT INTO #Print_Doc_Total SELECT 0

		SET @current_page = 0
		SET @order_total = 0	-- v10.6

		-- Loop to print reports per page
		WHILE @total_pages > @current_page
		BEGIN

			-- Call the commercial invoice routine
			EXEC CVO_Print_Commercial_Invoice_sp @order_no, @order_ext, 'SHP', 'PNTCOMMERCIAL', 'VB', '',@order_total OUTPUT -- v10.6

			-- Insert the format info
            INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PAGE_NO', ('Page ' + LTRIM(RTRIM(STR(@current_page + 1))) + ' of ' + LTRIM(RTRIM(STR(@total_pages)))))
            INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id

			-- Insert the print data
            INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + IsNull(data_value,'') FROM #PrintData

			-- Insert the print trailer info
            INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
            INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
            INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,' + LTRIM(RTRIM(STR(@number_of_copies)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

			DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID -- v10.1
			INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket -- v10.1
			DELETE FROM #tdc_print_ticket 

			--Create the file
			SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\COM-' + CAST(newid()AS VARCHAR(60)) + '.pas"'  -- v10.1
				
			EXEC master..xp_cmdshell  @xp_cmdshell, no_output

			IF @@ERROR <> 0
				SELECT -1

			SET @current_page = @current_page + 1
		END



-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Customs Invoice
--	Module = 'SHP' / trans = 'PNTCUSTOM'	
-- 
	DELETE #PrintData_detail
		-- Insert the print data	
			INSERT INTO #PrintData_detail (order_no, order_ext, carton_no, part_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value, schedule_B_no)
			SELECT	DISTINCT
					ol.order_no	AS order_no,
					ol.order_ext AS order_ext,
					ISNULL(cd.carton_no,0) AS Box, 
					ol.part_no AS part_no, 
					LEFT(ol.description,50) AS Description, 
					inv.type_code AS type_code,
					cvo.add_case AS add_case,
					cvo.line_no	AS line_no,
					cvo.from_line_no AS from_line_no,
					ISNULL( inv_add.field_10,'') AS Material, 
					ISNULL(gl.description,'') AS Origin, 
					CASE WHEN ol.shipped = 0 THEN ol.ordered ELSE ol.shipped END AS Qty,
					curr_price = CASE WHEN ol.shipped = 0 THEN  
						CASE cvo.is_amt_disc
						WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
						ELSE 
									 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
						END
					ELSE
						CASE cvo.is_amt_disc
						WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
						ELSE 
									 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
						END
					END,
					CASE WHEN ol.shipped = 0 THEN
						ol.ordered * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
					ELSE
						ol.shipped * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
					END AS Total_Value,
					ISNULL(com.cmdty_desc_1,'') AS schedule_B_no			-- v2.0
					-- ISNULL(inv.cmdty_code,'') AS schedule_B_no			-- v2.0
			FROM	ord_list ol (NOLOCK)
			JOIN	CVO_ord_list cvo (NOLOCK)
			ON		ol.order_no	= cvo.order_no		
			AND		ol.order_ext = cvo.order_ext		
			AND		ol.line_no = cvo.line_no	
			JOIN	inv_master inv (NOLOCK)
			ON		ol.part_no = inv.part_no
			JOIN	inv_master_add inv_add (NOLOCK)
			ON		ol.part_no = inv_add.part_no
			LEFT JOIN	gl_cmdty com (NOLOCK)							-- v2.0 -- v10.4
			ON		inv.cmdty_code = com.cmdty_code					-- v2.0
			JOIN	gl_country gl (NOLOCK)
			ON		inv.country_code = gl.country_code
			LEFT JOIN
					tdc_carton_detail_tx cd (NOLOCK)
			ON		ol.order_no	= cd.order_no
			AND		ol.order_ext = cd.order_ext
			AND		ol.line_no = cd.line_no
			LEFT JOIN -- v3.0 Only allocated or packed
					tdc_soft_alloc_tbl t (NOLOCK)
			ON		ol.order_no	= t.order_no
			AND		ol.order_ext = t.order_ext
			AND		ol.line_no = t.line_no
			-- START v10.5
			LEFT JOIN	
				cvo_soft_alloc_det d (NOLOCK) -- v3.0 Only when allocated or packed.
			ON		ol.order_no = d.order_no
			AND		ol.order_ext = d.order_ext
			AND		ol.line_no = d.line_no
			-- END v10.5
			WHERE	ol.order_no = @order_no
			AND		ol.order_ext = @order_ext	  
			AND	NOT	(t.order_no IS NULL AND cd.order_no IS NULL AND d.order_no IS NULL) -- v3.0 -- v10.5 - include soft allocations
-- v10.4			AND		ISNULL(com.rpt_flag_esl,0) = 1 -- v10.2

			-- START v10.5
			-- v10.0 Start - Update the quantity and values based on the allocated quantities
			/*
			UPDATE	a
			SET		qty = (SELECT SUM(qty) FROM tdc_soft_alloc_tbl b (NOLOCK) WHERE a.order_no = b.order_no
								AND a.order_ext = b.order_ext AND a.line_no = b.line_no AND a.part_no = b.part_no)
			FROM	#PrintData_detail a
			JOIN	tdc_soft_alloc_tbl c
			ON		a.order_no	= c.order_no
			AND		a.order_ext = c.order_ext
			AND		a.line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			*/
			UPDATE	a
			SET		qty = dbo.f_international_documents_qty (order_no, order_ext, line_no, part_no, carton_no) -- v11.3
			FROM	#PrintData_detail a
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			-- END v10.5

			UPDATE	#PrintData_detail
			SET		total_value = qty * unit_value
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			UPDATE	a
			SET		weight = qty * i.weight_ea
			FROM	#PrintData_detail a
			JOIN	inv_master i (NOLOCK)
			ON		a.part_no = i.part_no
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			-- v10.0 End

			-- v10.9
			DELETE	#PrintData_detail
			WHERE	CAST(qty AS decimal(20,8)) <= 0

			-- Get total lines to print
			SELECT	@line_count =  COUNT(*)+1 FROM #PrintData_detail WHERE type_code <> 'CASE'

			-- Get max detail_lines to print per page
			SET @max_lines = 0
			SELECT	@max_lines = detail_lines From tdc_tx_print_detail_config WHERE trans_source = 'VB' AND module = 'SHP' AND trans = 'PNTCUSTOM'

			-- Calculate the number of pages
			IF (@line_count % @max_lines) > 0 
				SET @total_pages = CAST((@line_count / @max_lines) AS INT) + 1
			ELSE
				SET @total_pages = @line_count / @max_lines

			SELECT @format_id = ISNULL(format_id,'')
			FROM   tdc_label_format_control (NOLOCK)
			WHERE  module = 'SHP'		
			AND	   trans = 'PNTCUSTOM'		
			AND    trans_source = 'VB'

			SELECT  @printer_id	= ISNULL(printer,0), 
					@number_of_copies = ISNULL(quantity,0)  
			FROM	tdc_tx_print_routing (NOLOCK)
			WHERE	module = 'SHP'		
			AND		trans = 'PNTCUSTOM'		
			AND		trans_source = 'VB' 
			AND		format_id = @format_id
			AND		user_station_id	= 999

			DELETE #Print_Doc_Total  	
			INSERT INTO #Print_Doc_Total SELECT 0

			-- v11.2 Start
			IF OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL  
				DROP TABLE #cvo_ord_list

			SELECT	* INTO #cvo_ord_list
			FROM	cvo_ord_list
			WHERE	1 = 2

			EXEC CVO_create_fc_relationship_sp @order_no, @order_ext

			UPDATE	a
			SET		from_line_no = b.from_line_no
			FROM	#PrintData_detail a
			JOIN	#cvo_ord_list b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	b.from_line_no <> 0

			SET @case  = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
			SELECT @LP_TOTAL_QTY = SUM(CAST(qty AS decimal(20,0)))
			FROM #PrintData_detail WHERE (type_code <> @case) OR (type_code = @case AND from_line_no = 0)
			-- v11.2 End

			SET @current_page = 0
			SET @is_lastpage = 0 -- v10.8
		              
			-- Loop to print reports per page
			WHILE @total_pages > @current_page
			BEGIN

				-- START v10.8
				IF (@current_page + 1) = @total_pages
				BEGIN
					SET @is_lastpage = 1
				END

				-- Call the custom invoice routine
				EXEC CVO_Print_Custom_Invoice_sp @order_no, @order_ext, 'SHP', 'PNTCUSTOM', 'VB', '', @is_lastpage, @LP_TOTAL_QTY -- v11.2
				-- END v10.8

				-- Insert the format info
				INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PAGE_NO', ('Page ' + LTRIM(RTRIM(STR(@current_page + 1))) + ' of ' + LTRIM(RTRIM(STR(@total_pages)))))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id

				-- Insert the print data
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + IsNull(data_value,'') FROM #PrintData

				-- Insert the print trailer info
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
				INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,' + LTRIM(RTRIM(STR(@number_of_copies)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

				DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID -- v10.1
				INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket -- v10.1
				DELETE FROM #tdc_print_ticket

				--Create the file
				SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\CUS-' + CAST(newid()AS VARCHAR(60)) + '.pas"'  -- v10.1
					
				EXEC master..xp_cmdshell  @xp_cmdshell, no_output

				IF @@ERROR <> 0
					SELECT -1

				SET @current_page = @current_page + 1
			END



-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Export Declaration
--	Module = 'SHP' / trans = 'PNTEXPORT'	
-- 
		-- v3.0
		-- If commodity values exceeds set amount then print the Export Declaration
		SELECT @customs_value = ISNULL(CAST(value_str as decimal(20,8)),0) FROM dbo.tdc_config WHERE [function] = 'CUSTOM_INV_VALUE' 


--		SELECT	@commodity_sum = SUM(CASE WHEN ol.shipped = 0 THEN
--					ol.ordered * curr_price
--				ELSE
--					ol.shipped * curr_price
--				END)
--		FROM	ord_list ol (NOLOCK)
--		JOIN	CVO_ord_list cvo (NOLOCK)
--		ON		ol.order_no	= cvo.order_no		
--		AND		ol.order_ext = cvo.order_ext		
--		AND		ol.line_no = cvo.line_no	
--		JOIN	inv_master inv (NOLOCK)
--		ON		ol.part_no = inv.part_no
--		JOIN	inv_master_add inv_add (NOLOCK)
--		ON		ol.part_no = inv_add.part_no
--		JOIN	gl_cmdty com (NOLOCK)							-- v2.0
--		ON		inv.cmdty_code = com.cmdty_code					-- v2.0
--		JOIN	gl_country gl (NOLOCK)
--		ON		inv.country_code = gl.country_code
--		LEFT JOIN
--				tdc_carton_detail_tx cd (NOLOCK)
--		ON		ol.order_no	= cd.order_no
--		AND		ol.order_ext = cd.order_ext
--		AND		ol.line_no = cd.line_no
--		LEFT JOIN
--				tdc_soft_alloc_tbl t (NOLOCK)
--		ON		ol.order_no	= t.order_no
--		AND		ol.order_ext = t.order_ext
--		AND		ol.line_no = t.line_no
--			WHERE	ol.order_no = @order_no
--			AND		ol.order_ext = @order_ext	  
--		AND	NOT	(t.order_no IS NULL AND cd.order_no IS NULL) 
--		GROUP BY ISNULL(com.cmdty_desc_1,'')
--		ORDER BY SUM(CASE WHEN ol.shipped = 0 THEN
--					ol.ordered * curr_price
--				ELSE
--					ol.shipped * curr_price
--				END) asc	


		DELETE #PrintData_detail
	-- Insert the print data	
		INSERT INTO #PrintData_detail (order_no, order_ext, carton_no, part_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value, schedule_B_no)
		SELECT	DISTINCT
				ol.order_no	AS order_no,
				ol.order_ext AS order_ext,
				ISNULL(cd.carton_no,0) AS Box, 
				ol.part_no AS part_no, 
				LEFT(ol.description,50) AS Description, 
				inv.type_code AS type_code,
				cvo.add_case AS add_case,
				cvo.line_no	AS line_no,
				cvo.from_line_no AS from_line_no,
				ISNULL( inv_add.field_10,'') AS Material, 
				ISNULL(gl.description,'') AS Origin, 
				CASE WHEN ol.shipped = 0 THEN ol.ordered ELSE ol.shipped END AS Qty,
				curr_price = CASE WHEN ol.shipped = 0 THEN  
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				ELSE
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				END,
				CASE WHEN ol.shipped = 0 THEN
					ol.ordered * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				ELSE
					ol.shipped * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				END AS Total_Value,
				ISNULL(com.cmdty_desc_1,'') AS schedule_B_no				-- v2.0
				-- ISNULL(inv.cmdty_code,'') AS schedule_B_no			-- v2.0
		FROM	ord_list ol (NOLOCK)
		JOIN	CVO_ord_list cvo (NOLOCK)
		ON		ol.order_no	= cvo.order_no		
		AND		ol.order_ext = cvo.order_ext		
		AND		ol.line_no = cvo.line_no	
		JOIN	inv_master inv (NOLOCK)
		ON		ol.part_no = inv.part_no
		JOIN	inv_master_add inv_add (NOLOCK)
		ON		ol.part_no = inv_add.part_no
		JOIN	gl_cmdty com (NOLOCK)							-- v2.0
		ON		inv.cmdty_code = com.cmdty_code					-- v2.0
		JOIN	gl_country gl (NOLOCK)
		ON		inv.country_code = gl.country_code
		LEFT JOIN
				tdc_carton_detail_tx cd (NOLOCK)
		ON		ol.order_no	= cd.order_no
		AND		ol.order_ext = cd.order_ext
		AND		ol.line_no = cd.line_no
		LEFT JOIN -- v3.0 Only allocated or packed
				tdc_soft_alloc_tbl t (NOLOCK)
		ON		ol.order_no	= t.order_no
		AND		ol.order_ext = t.order_ext
		AND		ol.line_no = t.line_no
		-- START v10.5
		LEFT JOIN	
			cvo_soft_alloc_det d (NOLOCK) 
		ON		ol.order_no = d.order_no
		AND		ol.order_ext = d.order_ext
		AND		ol.line_no = d.line_no
		-- END v10.5
		WHERE	ol.order_no = @order_no
		AND		ol.order_ext = @order_ext	  
		AND	NOT	(t.order_no IS NULL AND cd.order_no IS NULL AND d.order_no IS NULL) -- v3.0 -- v10.5 - include soft allocations
		AND inv.type_code NOT IN ('CASE','POP')						--v2.0 -- 7/12/2018 - don't include pop in export decl totals
		AND		ISNULL(com.rpt_flag_esl,0) = 1 -- v10.2

		-- START v10.5
		-- v10.0 Start - Update the quantity and values based on the allocated quantities
		/*
		UPDATE	a
		SET		qty = (SELECT SUM(qty) FROM tdc_soft_alloc_tbl b (NOLOCK) WHERE a.order_no = b.order_no
							AND a.order_ext = b.order_ext AND a.line_no = b.line_no AND a.part_no = b.part_no)
		FROM	#PrintData_detail a
		JOIN	tdc_soft_alloc_tbl c
		ON		a.order_no	= c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		*/
		UPDATE	a
		SET		qty = dbo.f_international_documents_qty (order_no, order_ext, line_no, part_no, carton_no) -- v11.3
		FROM	#PrintData_detail a
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		-- END v10.5

		UPDATE	#PrintData_detail
		SET		total_value = qty * unit_value
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		
		UPDATE	a
		SET		weight = qty * i.weight_ea
		FROM	#PrintData_detail a
		JOIN	inv_master i (NOLOCK)
		ON		a.part_no = i.part_no
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext


		-- v10.0 End


		-- v10.9
		DELETE	#PrintData_detail
		WHERE	CAST(qty AS decimal(20,8)) <= 0

		-- START v11.1
		DELETE #Order_value
		-- Insert the order data	
		INSERT INTO #Order_value (order_no, order_ext, part_no, type_code, line_no, qty, unit_value, total_value)
		SELECT	DISTINCT
				ol.order_no	AS order_no,
				ol.order_ext AS order_ext,
				ol.part_no AS part_no, 
				inv.type_code AS type_code,
				cvo.line_no	AS line_no,
				CASE WHEN ol.shipped = 0 THEN ol.ordered ELSE ol.shipped END AS Qty,
				curr_price = CASE WHEN ol.shipped = 0 THEN  
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				ELSE
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				END,
				CASE WHEN ol.shipped = 0 THEN
					ol.ordered * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				ELSE
					ol.shipped * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				END AS Total_Value
		FROM	ord_list ol (NOLOCK)
		JOIN	CVO_ord_list cvo (NOLOCK)
		ON		ol.order_no	= cvo.order_no		
		AND		ol.order_ext = cvo.order_ext		
		AND		ol.line_no = cvo.line_no	
		JOIN	inv_master inv (NOLOCK)
		ON		ol.part_no = inv.part_no
		LEFT JOIN -- v3.0 Only allocated or packed
				tdc_soft_alloc_tbl t (NOLOCK)
		ON		ol.order_no	= t.order_no
		AND		ol.order_ext = t.order_ext
		AND		ol.line_no = t.line_no
		-- START v10.5
		LEFT JOIN	
			cvo_soft_alloc_det d (NOLOCK) 
		ON		ol.order_no = d.order_no
		AND		ol.order_ext = d.order_ext
		AND		ol.line_no = d.line_no
		-- END v10.5
		LEFT JOIN
				tdc_carton_detail_tx cd (NOLOCK)
		ON		ol.order_no	= cd.order_no
		AND		ol.order_ext = cd.order_ext
		AND		ol.line_no = cd.line_no
		WHERE	ol.order_no = @order_no
		AND		ol.order_ext = @order_ext	  
		AND	NOT	(t.order_no IS NULL AND cd.order_no IS NULL AND d.order_no IS NULL) -- v3.0 -- v10.5 - include soft allocations
		AND inv.type_code NOT IN ('CASE','POP')						--v2.0


		UPDATE	a
		SET		qty = dbo.f_international_documents_qty (order_no, order_ext, line_no, part_no, NULL) -- v11.3
		FROM	#Order_value a
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext

		UPDATE	#Order_value
		SET		total_value = qty * unit_value
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		
		UPDATE	a
		SET		weight = qty * i.weight_ea
		FROM	#Order_value a
		JOIN	inv_master i (NOLOCK)
		ON		a.part_no = i.part_no
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		DELETE	#Order_value
		WHERE	CAST(qty AS decimal(20,8)) <= 0

		SELECT	@commodity_sum = SUM(total_value)		
		FROM #Order_value
		-- This is now calculated on the entire order value
		/*
		-- v10.0 Start
		SELECT	@commodity_sum = SUM(a.total_value)
		FROM	#PrintData_detail a
		JOIN	inv_master inv (NOLOCK)
		ON		a.part_no = inv.part_no
		JOIN	inv_master_add inv_add (NOLOCK)
		ON		a.part_no = inv_add.part_no
		JOIN	gl_cmdty com (NOLOCK)							-- v2.0
		ON		inv.cmdty_code = com.cmdty_code					-- v2.0
		JOIN	gl_country gl (NOLOCK)
		ON		inv.country_code = gl.country_code
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	  
		AND		ISNULL(com.rpt_flag_esl,0) = 1 -- v10.2
		GROUP BY ISNULL(com.cmdty_desc_1,'')
		ORDER BY SUM(a.total_value)
		*/
		-- END v11.1

		-- v11.4 Start
		UPDATE	#PrintData_detail
		SET		unit_value = 1.00,
				total_value = 1.00 * qty
		WHERE	unit_value <= 0
		AND		type_code IN ('FRAME','SUM')	
		-- v11.4 End

		IF @commodity_sum >= @customs_value
		BEGIN

			-- Get total lines to print
			SELECT	@line_count = COUNT(Distinct schedule_B_no) FROM #PrintData_detail

			-- Get max detail_lines to print per page
			SET @max_lines = 0
			SELECT	@max_lines = detail_lines From tdc_tx_print_detail_config WHERE trans_source = 'VB' AND module = 'SHP' AND trans = 'PNTCUSTOM'

			-- Calculate the number of pages
			IF (@line_count % @max_lines) > 0 
				SET @total_pages = CAST((@line_count / @max_lines) AS INT) + 1
			ELSE
				SET @total_pages = @line_count / @max_lines

			SELECT @format_id = ISNULL(format_id,'')
			FROM   tdc_label_format_control (NOLOCK)
			WHERE  module = 'SHP'		
			AND	   trans = 'PNTEXPORT'		
			AND    trans_source = 'VB'

			SELECT  @printer_id	= ISNULL(printer,0), 
					@number_of_copies = ISNULL(quantity,0)  
			FROM	tdc_tx_print_routing (NOLOCK)
			WHERE	module = 'SHP'		
			AND		trans = 'PNTEXPORT'		
			AND		trans_source = 'VB' 
			AND		format_id = @format_id
			AND		user_station_id	= 999

			SET @current_page = 0
		              
			-- Loop to print reports per page
			WHILE @total_pages > @current_page
			BEGIN

				-- Call the Export Declaration routine
				EXEC CVO_Print_Export_Declaration_sp @order_no, @order_ext, 'SHP', 'PNTEXPORT', 'VB', ''

				-- Insert the format info
				INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PAGE_NO', ('Page ' + LTRIM(RTRIM(STR(@current_page + 1))) + ' of ' + LTRIM(RTRIM(STR(@total_pages)))))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id

				-- Insert the print data
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + IsNull(data_value,'') FROM #PrintData

				-- Insert the print trailer info
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
				INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,' + LTRIM(RTRIM(STR(@number_of_copies)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

				DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID -- v10.1
				INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket -- v10.1
				DELETE FROM #tdc_print_ticket

				--Create the file
				SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\CUS-' + CAST(newid()AS VARCHAR(60)) + '.pas"'  -- v10.1
					
				EXEC master..xp_cmdshell  @xp_cmdshell, no_output

				IF @@ERROR <> 0
					SELECT -1

				SET @current_page = @current_page + 1
			END
		END


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Caricom Document
--	Module = 'SHP' / trans = 'PNTCARICOM'	
-- 
	IF EXISTS (SELECT 1 FROM CVO_Carribean_Countries_tbl WHERE country_code = @country_code)
	BEGIN

	DELETE #PrintData_detail
		-- Insert the print data	
		INSERT INTO #PrintData_detail (order_no, order_ext, carton_no, part_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value, schedule_B_no)
		SELECT	DISTINCT
				ol.order_no	AS order_no,
				ol.order_ext AS order_ext,
				ISNULL(cd.carton_no,0) AS Box, 
				ol.part_no AS part_no, 
				LEFT(ol.description,50) AS Description, 
				inv.type_code AS type_code,
				cvo.add_case AS add_case,
				cvo.line_no	AS line_no,
				cvo.from_line_no AS from_line_no,
				ISNULL( inv_add.field_10,'') AS Material, 
				ISNULL(gl.description,'') AS Origin, 
				CASE WHEN ol.shipped = 0 THEN ol.ordered ELSE ol.shipped END AS Qty,
				curr_price = CASE WHEN ol.shipped = 0 THEN  
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				ELSE
					CASE cvo.is_amt_disc
					WHEN 'Y' THEN ol.curr_price -  ROUND((cvo.amt_disc),2) -- v10.3
					ELSE 
								 ol.curr_price - ROUND(ol.curr_price * (ol.discount /100),2) -- v10.3
					END
				END,
				CASE WHEN ol.shipped = 0 THEN
					ol.ordered * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				ELSE
					ol.shipped * curr_price - ROUND(cvo.amt_disc,2)				--v4.0	TM -- v10.3
				END AS Total_Value,
				ISNULL(com.cmdty_desc_1,'') AS schedule_B_no			-- v2.0
				-- ISNULL(inv.cmdty_code,'') AS schedule_B_no			-- v2.0
		FROM	ord_list ol (NOLOCK)
		JOIN	CVO_ord_list cvo (NOLOCK)
		ON		ol.order_no	= cvo.order_no		
		AND		ol.order_ext = cvo.order_ext		
		AND		ol.line_no = cvo.line_no	
		JOIN	inv_master inv (NOLOCK)
		ON		ol.part_no = inv.part_no
		JOIN	inv_master_add inv_add (NOLOCK)
		ON		ol.part_no = inv_add.part_no
		LEFT JOIN	gl_cmdty com (NOLOCK)							-- v2.0 -- v10.4
		ON		inv.cmdty_code = com.cmdty_code					-- v2.0
		JOIN	gl_country gl (NOLOCK)
		ON		inv.country_code = gl.country_code
		LEFT JOIN
				tdc_carton_detail_tx cd (NOLOCK)
		ON		ol.order_no	= cd.order_no
		AND		ol.order_ext = cd.order_ext
		AND		ol.line_no = cd.line_no
		LEFT JOIN -- v3.0 Only allocated or packed
				tdc_soft_alloc_tbl t (NOLOCK)
		ON		ol.order_no	= t.order_no
		AND		ol.order_ext = t.order_ext
		AND		ol.line_no = t.line_no
		-- START v10.5
		LEFT JOIN	
			cvo_soft_alloc_det d (NOLOCK) 
		ON		ol.order_no = d.order_no
		AND		ol.order_ext = d.order_ext
		AND		ol.line_no = d.line_no
		-- END v10.5
		WHERE	ol.order_no = @order_no
		AND		ol.order_ext = @order_ext	  
		AND	NOT	(t.order_no IS NULL AND cd.order_no IS NULL AND d.order_no IS NULL) -- v3.0 -- v10.5 - include soft allocations
-- v10.4		AND		ISNULL(com.rpt_flag_esl,0) = 1 -- v10.2

		-- START v10.5
		-- v10.0 Start - Update the quantity and values based on the allocated quantities
		/*
		UPDATE	a
		SET		qty = (SELECT SUM(qty) FROM tdc_soft_alloc_tbl b (NOLOCK) WHERE a.order_no = b.order_no
							AND a.order_ext = b.order_ext AND a.line_no = b.line_no AND a.part_no = b.part_no)
		FROM	#PrintData_detail a
		JOIN	tdc_soft_alloc_tbl c
		ON		a.order_no	= c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		*/

		UPDATE	a
		SET		qty = dbo.f_international_documents_qty (order_no, order_ext, line_no, part_no, carton_no) -- v11.3
		FROM	#PrintData_detail a
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		-- END v10.5

		UPDATE	#PrintData_detail
		SET		total_value = qty * unit_value
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		UPDATE	a
		SET		weight = qty * i.weight_ea
		FROM	#PrintData_detail a
		JOIN	inv_master i (NOLOCK)
		ON		a.part_no = i.part_no
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		-- v10.0 End

		-- v10.9
		DELETE	#PrintData_detail
		WHERE	CAST(qty AS decimal(20,8)) <= 0

		-- Get total lines to print
		SELECT	@line_count =  COUNT(*)+1 FROM #PrintData_detail WHERE type_code <> 'CASE'

		-- Get max detail_lines to print per page
		SET @max_lines = 0
		SELECT	@max_lines = detail_lines From tdc_tx_print_detail_config WHERE trans_source = 'VB' AND module = 'SHP' AND trans = 'PNTCARICOM'

		-- Calculate the number of pages
		IF (@line_count % @max_lines) > 0 
			SET @total_pages = CAST((@line_count / @max_lines) AS INT) + 1
		ELSE
			SET @total_pages = @line_count / @max_lines

		SELECT @format_id = ISNULL(format_id,'')
		FROM   tdc_label_format_control (NOLOCK)
		WHERE  module = 'SHP'		
		AND	   trans = 'PNTCARICOM'		
		AND    trans_source = 'VB'

		SELECT  @printer_id	= ISNULL(printer,0), 
				@number_of_copies = ISNULL(quantity,0)  
		FROM	tdc_tx_print_routing (NOLOCK)
		WHERE	module = 'SHP'		
		AND		trans = 'PNTCARICOM'		
		AND		trans_source = 'VB' 
		AND		format_id = @format_id
		AND		user_station_id	= 999

		DELETE #Print_Doc_Total  	
		INSERT INTO #Print_Doc_Total SELECT 0			--v4.0

		SET @current_page = 0
	    SET @is_lastpage = 0 -- v10.7          
	              
		-- Loop to print reports per page
		WHILE @total_pages > @current_page
		BEGIN

			-- START v10.7
			IF (@current_page + 1) = @total_pages
			BEGIN
				SET @is_lastpage = 1
			END

			-- Call the commercial invoice routine
			EXEC CVO_Print_Caricom_Invoice_sp @order_no, @order_ext, 'SHP', 'PNTCARICOM', 'VB', '', @is_lastpage
			-- END v10.7

			-- Insert the format info
            INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PAGE_NO', ('Page ' + LTRIM(RTRIM(STR(@current_page + 1))) + ' of ' + LTRIM(RTRIM(STR(@total_pages)))))
            INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id

			-- Insert the print data
            INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + IsNull(data_value,'') FROM #PrintData

			-- Insert the print trailer info
            INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
            INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
            INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,' + LTRIM(RTRIM(STR(@number_of_copies)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'

			DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID -- v10.1
			INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket -- v10.1
			DELETE FROM #tdc_print_ticket

			--Create the file
			SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + '  order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\CAR-' + CAST(newid()AS VARCHAR(60)) + '.pas"'  -- v10.1
				
			EXEC master..xp_cmdshell  @xp_cmdshell, no_output

			IF @@ERROR <> 0
				SELECT -1

			SET @current_page = @current_page + 1
		END
	END
END

SELECT 0

END

GO
GRANT EXECUTE ON  [dbo].[cvo_adm_print_international_documents_sp] TO [public]
GO
