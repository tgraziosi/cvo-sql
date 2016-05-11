SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v1.0 CT 07/03/2014 - Issue #1454 - Automate the printing of pick tickets
-- v1.1 CT 24/03/2014 - Issue #1459 - Additional logic for past order processing
-- v1.2 CB 08/01/2015 - Auto print routine not dealing with consolidated picks
-- v1.3 CB 07/04/2015 - Check that the order has been allocated before printing
-- v1.4 CB 18/06/2015 - Add in a delay when picking up orders to print to stop partial labels being produced
-- v1.5 CB 09/07/2015 - If any part of a ST consolidated order is not allocated then remove from printing
-- v1.6 CB 27/07/2015 - Print file failing - check for PRINTLABEL in file data and ignore if not there
-- v1.7 CB 29/07/2015 - Need to expand v1.5 for consolidation orders
-- v1.8 CB 14/04/2016 - #1596 - Add promo level

-- EXEC dbo.cvo_auto_print_pick_tickets_sp 'ST'
CREATE PROC [dbo].[cvo_auto_print_pick_tickets_sp] (@order_type	VARCHAR(2))

AS
BEGIN

	SET NOCOUNT ON

	DECLARE @where_clause		VARCHAR(2000),
			@print_order		SMALLINT,
			@template			VARCHAR(255),
			@today				VARCHAR(8),
			@in_where_clause1	VARCHAR(255),
			@in_where_clause2	VARCHAR(255),
			@in_where_clause3	VARCHAR(255),
			@in_where_clause4	VARCHAR(255),
			@char				CHAR(1),
			@pos				SMALLINT,
			@rec_id				INT,
			@order_no			INT,
			@ext				INT,
			@msg				VARCHAR(1000),
			-- START v1.1
			@yesterday			VARCHAR(8),
			@oldest				VARCHAR(8),
			@date_entered		DATETIME,
			-- END v1.1
			@cons_no			int, -- v1.2
			@location			varchar(10), -- v1.2
			@xp_cmdshell		varchar(1000), -- v1.2
			@lwlPath			varchar (100), -- v1.2
			@rows				int

	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory' -- v1.2

	EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, NULL, NULL, NULL, 'Starting auto print routine'

	-- Create temporary tables
	CREATE TABLE #print_order (
		rec_id					INT IDENTITY (1,1),		
		order_no				INT,
		ext						INT,
		template				VARCHAR(255),
		location				varchar(10), -- v1.2
		cons_no					int)-- v1.2

	CREATE TABLE #so_pick_ticket_details (                                                  
		order_no				INT NULL,        
		order_ext				INT NULL,        
		con_no					INT NOT NULL,        
		[status]				CHAR(1) NOT NULL,        
		location				VARCHAR(10) NULL,        
		sch_ship_date			DATETIME NULL,        
		cust_name				VARCHAR(255) NULL,        
		curr_alloc_pct			DECIMAL(20,2) NULL,        
		sel_flg					INT NOT NULL,        
		alloc_type				VARCHAR(2) NULL,        
		total_pieces			INT NULL,        
		lowest_bin_no			VARCHAR(12) NULL,        
		highest_bin_no			VARCHAR(12) NULL,         
		cust_code				VARCHAR(10) NULL,         
		consolidate_shipment	INT NOT NULL,       
		promo_id                VARCHAR(20) NULL,
		promo_level				VARCHAR(20) NULL) -- v1.8   

	CREATE TABLE #temp_who (
		who						VARCHAR(50),
		login_id				VARCHAR(50))
	
	INSERT INTO #temp_who (who, login_id) VALUES ('manager', 'manager')

	-- START v1.1
	-- Get oldest order date
	SELECT 
		@date_entered = MIN(date_entered)
	FROM
		dbo.orders_all (NOLOCK)
	WHERE
		[status] = 'N'
		AND [type] = 'I'
		AND ext = 0

	-- Convert dates to format used by pick ticket routine
	SELECT @yesterday = CONVERT(VARCHAR(8),DATEADD(day, -1,GETDATE()),1)
	SELECT @oldest = CONVERT(VARCHAR(8),@date_entered,1)
	-- END v1.1

	-- Convert today's date to format used by pick ticket routine
	SELECT @today = CONVERT(VARCHAR(8),GETDATE(),1)

	-- Work through templates for the order type
	SET @print_order = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@print_order = print_order,
			@where_clause = where_clause,
			@template = template_desc
		FROM
			dbo.cvo_auto_print_pick_tickets_templates (NOLOCK)
		WHERE
			order_type = @order_type
			AND print_order > @print_order
			AND ISNULL(where_clause,'') <> ''
		ORDER BY
			print_order

		IF @@ROWCOUNT = 0
			BREAK

	
		-- Update WHERE clause with date place holders
		-- START v1.1
		SET @where_clause = REPLACE(@where_clause,'*YESTERDAY*',@yesterday)
		SET @where_clause = REPLACE(@where_clause,'*OLDEST*',@oldest)
		-- END v1.1
		SET @where_clause = REPLACE(@where_clause,'*TODAY*',@today)


		IF LEN(@where_clause) <= 1020
		BEGIN

			-- Split up where clause to pass into pick ticket routine
			SET @in_where_clause1 = ''
			SET @in_where_clause2 = ''
			SET @in_where_clause3 = ''
			SET @in_where_clause4 = ''

			-- 1. Where clause 1
			IF @where_clause <> ''
			BEGIN
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause1 = @where_clause
					SET @where_clause = ''
				END
				ELSE
				BEGIN
					SET @pos = 255	
					SELECT @pos = dbo.f_string_split_position (@where_clause,@pos)
					SELECT @in_where_clause1 = SUBSTRING(@where_clause,1,@pos)
					SELECT @where_clause = SUBSTRING(@where_clause,@pos + 1,(LEN(@where_clause)- @pos))
				END
			END

			-- 2. Where clause 2
			IF @where_clause <> ''
			BEGIN
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause2 = @where_clause
					SET @where_clause = ''
				END
				ELSE
				BEGIN
					SET @pos = 255	
					SELECT @pos = dbo.f_string_split_position (@where_clause,@pos)
					SELECT @in_where_clause2 = SUBSTRING(@where_clause,1,@pos)
					SELECT @where_clause = SUBSTRING(@where_clause,@pos + 1,(LEN(@where_clause)- @pos))
				END
			END
			
			-- 3. Where clause 3
			IF @where_clause <> ''
			BEGIN
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause3 = @where_clause
					SET @where_clause = ''
				END
				ELSE
				BEGIN
					SET @pos = 255	
					SELECT @pos = dbo.f_string_split_position (@where_clause,@pos)
					SELECT @in_where_clause3 = SUBSTRING(@where_clause,1,@pos)
					SELECT @where_clause = SUBSTRING(@where_clause,@pos + 1,(LEN(@where_clause)- @pos))
				END
			END
			
			-- 4. Where clause 4
			IF @where_clause <> ''
			BEGIN
		
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause4 = @where_clause
				END
				ELSE
				BEGIN
					EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, @template, NULL, NULL, 'Error creating where clause - clause4 too long'
					RETURN -- v1.1
				END
				
			END

			-- Clear working table
			DELETE FROM #so_pick_ticket_details

			-- Get pick tickets
			EXEC tdc_plw_so_print_selection_sp 0, @in_where_clause1, @in_where_clause2, @in_where_clause3, @in_where_clause4

			-- Get lowest bin number for pick tickets
			EXEC CVO_pick_list_print_by_lowest_bin_no_sp 

			-- Load results into print table
			INSERT INTO #print_order(
				order_no,
				ext,
				template,
				location) -- v1.2
			SELECT 
				order_no,
				order_ext,
				@template,
				location -- v1.2 
			FROM 
				#so_pick_ticket_details 
			ORDER BY 
				lowest_bin_no, 
				order_no,
				order_ext

				


			-- v1.3 Start
			DELETE	a
			FROM	#so_pick_ticket_details a
			LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		b.order_type = 'S'
			WHERE	b.order_no IS NULL
			AND		b.order_ext IS NULL
			-- v1.3

			-- v1.4 Start
			CREATE TABLE #created (
				order_no		int,
				order_ext		int,
				date_created	datetime,
				remove_recs		int)

			INSERT	#created (order_no, order_ext, date_created, remove_recs)
			SELECT	a.trans_type_no,
					a.trans_type_ext,
					MAX(date_time),
					0
			FROM	tdc_pick_queue a (NOLOCK)
			JOIN	#so_pick_ticket_details b
			ON		a.trans_type_no = b.order_no
			AND		a.trans_type_ext = b.order_ext
			GROUP BY a.trans_type_no,
					a.trans_type_ext

			UPDATE	#created
			SET		remove_recs = 1
			WHERE	DATEDIFF(n,date_created,GETDATE()) < 2

			DELETE	a
			FROM	#so_pick_ticket_details a
			JOIN	#created b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			WHERE	b.remove_recs = 1

			-- v1.7 Start
			DELETE	a
			FROM	#print_order a
			JOIN	#created b
			ON		a.order_no = b.order_no
			AND		a.ext = b.order_ext
			WHERE	b.remove_recs = 1
			-- v1.7 End
			
			DROP TABLE #created

			-- v1.7 Start
			CREATE TABLE #createdcons (
				con_no			int,
				date_created	datetime,
				remove_recs		int)

			INSERT	#createdcons (con_no, date_created, remove_recs)
			SELECT	a.mp_consolidation_no,
					MAX(date_time),
					0
			FROM	tdc_pick_queue a (NOLOCK)
			JOIN	#so_pick_ticket_details b
			ON		a.trans_type_no = b.order_no
			AND		a.trans_type_ext = b.order_ext
			WHERE	a.mp_consolidation_no IS NOT NULL
			GROUP BY a.mp_consolidation_no

			UPDATE	#createdcons
			SET		remove_recs = 1
			WHERE	DATEDIFF(n,date_created,GETDATE()) < 2

			DELETE	a
			FROM	#so_pick_ticket_details a
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			JOIN	#createdcons c
			ON		b.consolidation_no = c.con_no
			WHERE	c.remove_recs = 1

			-- v1.7 Start
			DELETE	a
			FROM	#print_order a
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.ext = b.order_ext
			JOIN	#createdcons c
			ON		b.consolidation_no = c.con_no
			WHERE	c.remove_recs = 1
			-- v1.7 End
			
			DROP TABLE #createdcons



			-- v1.4 End

			SELECT @rows = COUNT(1) FROM #print_order -- v1.7
			SET @msg = CAST(@rows AS VARCHAR(6)) + ' pick ticket(s) selected for printing' -- v1.7
			EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, @template, NULL, NULL, @msg

		END
		ELSE
		BEGIN
			EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, @template, NULL, NULL, 'Error creating where clause - clause too long'
		END

	END

	-- If there is anything to print then print it
	IF EXISTS (SELECT 1 FROM #print_order)
	BEGIN
		-- v1.5 Start
		CREATE TABLE #st_cons_check (consolidation_no int)
		
		INSERT  #st_cons_check (consolidation_no)
		SELECT	b.consolidation_no 
		FROM	#print_order a 
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK) 
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext 
		AND		b.consolidation_no IN (
			SELECT	e.consolidation_no
			FROM	cvo_masterpack_consolidation_det e
			LEFT JOIN tdc_soft_alloc_tbl c 
			ON		e.order_no = c.order_no 
			AND		e.order_ext = c.order_ext
			WHERE	c.order_no IS NULL OR c.qty = 0)

		DELETE	a
		FROM	#print_order a 
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK) 
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext 
		JOIN	#st_cons_check c 
		ON		b.consolidation_no = c.consolidation_no

		DROP TABLE #st_cons_check
		-- v1.5 End

		-- v1.2 Start
		-- If the orders are part of a consolidation then remove all but one order per consolidation
		UPDATE	a
		SET		cons_no = b.consolidation_no
		FROM	#print_order a
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext

		CREATE TABLE #cons (
			order_no	int,
			cons_no		int)

		INSERT	#cons
		SELECT	MIN(order_no), 
				cons_no
		FROM	#print_order
		WHERE	cons_no IS NOT NULL
		GROUP BY cons_no

		DELETE	a
		FROM	#print_order a
		LEFT JOIN #cons b
		ON		a.order_no = b.order_no
		WHERE	b.order_no IS NULL
		AND		a.cons_no IS NOT NULL

		DROP TABLE #cons
		-- v1.2 End

		SET @rec_id = 0		

		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				@order_no = order_no,
				@ext = ext,
				@template = template,
				@cons_no = cons_no, -- v1.2
				@location = location -- v1.2
			FROM
				#print_order
			WHERE
				rec_id > @rec_id
			ORDER BY
				rec_id

			IF @@ROWCOUNT = 0	
				BREAK

			-- Print pick ticket
			-- v1.2 Start
			IF (@cons_no IS NOT NULL)
			BEGIN

				IF OBJECT_ID('tempdb..#so_pick_ticket') IS NULL 
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

				TRUNCATE TABLE #so_pick_ticket                                  

				INSERT INTO #so_pick_ticket (cons_no, order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, dest_bin,    
								ord_qty, pick_qty, part_type, [user_id], order_date, cust_po, sch_ship_date, carrier_desc,    
								ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_city, ship_to_country, ship_to_name,    
								ship_to_state, ship_to_zip, special_instr, order_note, uom, item_note, [description], customer_name,    
								addr1, addr2, addr3, addr4, addr5, cust_code, kit_caption, cancel_date, kit_id, group_code_id, seq_no,       
								trans_type, tran_id)    
				SELECT	DISTINCT d.consolidation_no, c.trans_type_no, c.trans_type_ext, c.location, c.line_no, c.part_no, c.lot, c.bin_no, c.next_op,
						f.ordered, c.qty_to_process, f.part_type,'AutoPrint', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,    
										NULL, NULL, NULL, f.uom, note, NULL, NULL, NULL,  NULL, NULL, NULL,  NULL, NULL, NULL,  NULL, NULL, NULL,  NULL,    
										c.trans, c.tran_id  
				FROM	cvo_masterpack_consolidation_picks a (NOLOCK)
				JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
				ON		a.consolidation_no = b.consolidation_no
				JOIN	tdc_pick_queue c (NOLOCK)
				ON		a.child_tran_id = c.tran_id
				JOIN	tdc_cons_ords d (NOLOCK)
				ON		c.trans_type_no = d.order_no     
				AND		c.trans_type_ext = d.order_ext
				JOIN	cvo_ord_list e (NOLOCK) 
				ON		c.trans_type_no = e.order_no  -- v10.1  
				AND		c.trans_type_ext = e.order_ext -- v10.1  
				AND		c.line_no = e.line_no
				JOIN	ord_list f (NOLOCK)
				ON		c.trans_type_no = f.order_no     
				AND		c.trans_type_ext = f.order_ext     
				AND		c.line_no = f.line_no
				WHERE	b.consolidation_no = @cons_no
				AND		c.trans_source = 'PLW'     


				UPDATE	#so_pick_ticket    
				SET		order_date = b.date_entered,  
						cust_po = b.cust_po,    
						sch_ship_date = b.sch_ship_date, 
						order_note = b.note,    
						carrier_desc = b.routing,       
						ship_to_add_1 = b.ship_to_add_1,    
						ship_to_add_2 = b.ship_to_add_2, 
						ship_to_add_3 = b.ship_to_add_3,    
						ship_to_city = b.ship_to_city,  
						ship_to_country = b.ship_to_country,    
						ship_to_name = b.ship_to_name,  
						ship_to_state = b.ship_to_state,    
						ship_to_zip = b.ship_to_zip, special_instr = b.special_instr,            
						[description] = c.[description], 
						customer_name = d.customer_name,    
						addr1 = d.addr1, 
						addr2 = d.addr2,      
						addr3 = d.addr3,
						addr4 = d.addr4,  
						addr5 = d.addr5    
				FROM	#so_pick_ticket a 
				JOIN	orders_all b (NOLOCK)
				ON		a.order_no  = b.order_no     
				AND		a.order_ext = b.ext 
				JOIN	inv_master c (NOLOCK)
				ON		a.part_no   = c.part_no     
				JOIN	arcust d (NOLOCK)    
				ON		b.cust_code = d.customer_code    

				UPDATE  #so_pick_ticket    
				SET		cust_code = b.cust_code,    
						cancel_date = b.cancel_date    
				FROM	#so_pick_ticket a
				JOIN	orders_all b (NOLOCK)    
				ON		a.order_no = b.order_no    
				AND		a.order_ext = b.ext  

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

				IF (object_id('tempdb..#PrintData') IS NULL)
				BEGIN
					CREATE TABLE #PrintData (
						data_field		varchar(300) NOT NULL,    
						data_value		varchar(300) NULL)
				END

				IF (object_id('tempdb..#Select_Result') IS NULL)
				BEGIN
					CREATE TABLE #Select_Result (
						data_field		varchar(300) NOT NULL,    
						data_value		varchar(300) NULL)    
				END

				IF (object_id('tempdb..#PrintData_detail') IS NULL)
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

				-- v1.7 Start
				IF EXISTS (SELECT 1 FROM #so_pick_ticket)
				BEGIN

					EXEC dbo.cvo_print_plw_so_consolidated_pick_ticket_sp 'AutoPrint', '999', @order_no, @ext, @location, @cons_no

					-- Move the print data into a permanent table so it can be access by the xp_cmdshell
					DELETE FROM CVO_tdc_print_ticket WHERE process_id = @@SPID
					INSERT CVO_tdc_print_ticket (print_value, process_id) SELECT print_value, @@SPID FROM #tdc_print_ticket ORDER BY row_id 
				
					-- v1.6 Start
					IF EXISTS (SELECT 1 FROM #tdc_print_ticket WHERE print_value = '*PRINTLABEL')
					BEGIN

						--Create the file
						SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() + '.dbo.CVO_tdc_print_ticket (NOLOCK) WHERE process_id = ' + CAST(@@SPID AS varchar(10)) + ' order by row_id" -s"," -h -1 -W -b -o  "' + @lwlPath  + '\PTK-' + CAST(newid()AS VARCHAR(60)) + '.pas"'   
						
						EXEC master..xp_cmdshell  @xp_cmdshell, no_output

						IF @@Error <> 0
							RETURN

						UPDATE	a
						SET		status = 'Q',
								printed = 'Q'
						FROM	orders_all a
						JOIN	cvo_masterpack_consolidation_det b
						ON		a.order_no = b.order_no
						AND		a.ext = b.order_ext
						WHERE	b.consolidation_no = @cons_no
						AND		a.status < 'P' -- Added by Tine 18/03/2015

					END
					-- v1.6
				END -- v1.7

				DROP TABLE #tdc_print_ticket 
				DROP TABLE #PrintData_Output
				DROP TABLE #PrintData
				DROP TABLE #Select_Result
				DROP TABLE #PrintData_detail


				IF EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE [status] = 'Q' AND order_no = @order_no AND ext = @ext)
				BEGIN
					SET @msg = 'Pick ticket printed'

					-- Write log record
					INSERT INTO dbo.tdc_log 
						(tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data) 
					SELECT  
						GETDATE() , 'AutoPrint' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , location , '' ,'STATUS:Q; HOLD REASON:' 
					FROM    
						dbo.orders_all a (NOLOCK) 
					JOIN
						cvo_masterpack_consolidation_det b
					ON
						a.order_no = b.order_no
					AND	a.ext = b.order_ext
					WHERE   
						b.consolidation_no = @cons_no
				END
				ELSE
				BEGIN
					SET @msg = 'Pick ticket NOT printed'
				END
				
				EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, @template, @order_no, @ext, @msg

			END
			ELSE 
			BEGIN -- v1.2 End
				EXEC dbo.cvo_print_pick_ticket_sp @order_no, @ext, 0

				-- Check if this order printed correctly
				IF EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE [status] = 'Q' AND order_no = @order_no AND ext = @ext)
				BEGIN
					SET @msg = 'Pick ticket printed'

					-- Write log record
					INSERT INTO dbo.tdc_log 
						(tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data) 
					SELECT  
						GETDATE() , 'AutoPrint' , 'VB' , 'PLW' , 'PICK TICKET' , order_no , ext , '' , '' , '' , location , '' ,'STATUS:Q; HOLD REASON:' 
					FROM    
						dbo.orders_all a (NOLOCK) 
					WHERE   
						order_no = @order_no 
						AND ext = @ext
				END
				ELSE
				BEGIN
					SET @msg = 'Pick ticket NOT printed'
				END
				
				EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, @template, @order_no, @ext, @msg
			END -- v1.2 End
		END


	END

	EXEC dbo.cvo_auto_print_pick_tickets_log_sp @order_type, NULL, NULL, NULL, 'Stopping auto print routine'


END

GO
GRANT EXECUTE ON  [dbo].[cvo_auto_print_pick_tickets_sp] TO [public]
GO
