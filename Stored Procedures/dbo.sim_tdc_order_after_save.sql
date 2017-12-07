SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sim_tdc_order_after_save]	@order_no int,  
												@ext int  
AS  
BEGIN
	-- NOTE: Based on tdc_order_after_save v3.1 - All changes must be kept in sync

  
	DECLARE	 @status   char(1),  
			 @order_type      char(1),  
			 @line_no  int,  
			 @location  varchar(10),  
			 @part_no  varchar(30),  
			 @cust_kit  char(1),  
			 @ordered  decimal(20, 8),  
			 @alloc_qty  decimal(20, 8),  
			 @shipped  decimal(20, 8),  
			 @allocate_line  int,  
			 @unallocate_line int,  
			 @kit_line  int,  
			 @kit_ordered  decimal(20, 8),   
			 @kit_allocated   decimal(20, 8),  
			 @kit_shipped  decimal(20, 8),  
			 @user_id  varchar(50),  
			 @template_code  varchar(20),  
			 @alloc_type  varchar(2),  
			 @pre_pack_flg    char(1),  
			 @con_no    int,  
			 @next_con_no  int,  
			 @con_name  varchar(20),  
			 @con_desc  varchar(255),  
			 @ret   int,
			 @ret1	int ,
			 @last_line int,
			 @order_ext int,
			 @part_type varchar(10),
			 @qty decimal(20,8),
			 @part_no_original varchar(30)

    
	SET @user_id = 'AUTO_ALLOC'  
   
	-- In order to allocate a SO: 1. tdc_config.flag = 'so_auto_allocate' MUST BE active = 'Y'  
	--                            2. the status MUST BE >= 'N' OR < 'R' AND type = 'I'   
				 --------------  
	IF (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y' RETURN 0 -- Exit out --  
             --------------  
  
	SELECT	@status = status,  
			@order_type = type  
	FROM	orders (NOLOCK)   
	WHERE	order_no = @order_no   
	AND		ext = @ext  
		   --------------  
	IF @order_type != 'I' RETURN 0    -- Exit out --  
		   --------------  
  
  
	-- Make sure that the order-ext passes the criteria filter  
	EXEC @ret = tdc_auto_alloc_criteria_validate @order_no, @ext, @template_code OUTPUT  
  
	IF @ret < 0 RETURN -99  
 
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK)
					WHERE order_no = @order_no AND ext = @ext
					AND ISNULL(allocation_date,GETDATE()-1) < GETDATE())
	BEGIN
		RETURN - 99
	END

	IF NOT EXISTS(SELECT * FROM tdc_plw_process_templates (NOLOCK) WHERE UserID = @user_id)  
	BEGIN  
		RAISERROR ('Must setup process template for user ''AUTO_ALLOC''', 16, 1)  
		RETURN -1  
	END  

  
	IF NOT EXISTS(SELECT * FROM tdc_plw_criteria_templates (NOLOCK) WHERE UserID = @user_id)  
	BEGIN  
		RAISERROR ('Must setup criteria template for user ''AUTO_ALLOC''', 16, 1)  
		RETURN -1  
	END  

	--next condition is because tdc_order_after_save is called by second time and we do not need to execute it 
	IF EXISTS(SELECT * FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND is_customized = 'S') 
		AND EXISTS(SELECT * FROM cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND flag_print = 2)
	BEGIN -- v1.0 only return if the allocations already exist otherwise we need to do them.
		IF EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext)
			RETURN 0
	END
	  
	DECLARE @o int, @e int, @l varchar(10), @li int, @p varchar(30)  
  
	------ Create temp tables -------------------------------------------------------------------------  
	IF OBJECT_ID('tempdb..#so_alloc_management')   IS NOT NULL DROP TABLE #so_alloc_management   
	IF OBJECT_ID('tempdb..#so_soft_alloc_byline_tbl') IS NOT NULL DROP TABLE #so_soft_alloc_byline_tbl   
	IF OBJECT_ID('tempdb..#so_alloc_err')     IS NOT NULL DROP TABLE #so_alloc_err  
 
	CREATE TABLE #so_alloc_management  
	(                
		 sel_flg               int             NOT NULL,   
		 sel_flg2              int             NOT NULL,   
		 prev_alloc_pct        decimal(5,2)    NOT NULL,   
		 curr_alloc_pct        decimal(5,2)    NOT NULL,   
		 curr_fill_pct         decimal(5,2)    NOT NULL,   
		 order_no              int             NOT NULL,   
		 order_ext             int             NOT NULL,   
		 location              varchar(10)     NOT NULL,   
		 order_status             char(1)         NOT NULL,   
		 sch_ship_date         datetime        NOT NULL,   
		 consolidation_no  int      NULL,   
		 cust_type    varchar(40)     NULL,  
		 cust_type2    varchar(40)      NULL,  
		 cust_type3    varchar(40)      NULL,  
		 cust_name    varchar(40)      NULL,  
		 cust_flg    char(1)      NULL,   
		 cust_code    varchar(10)  NOT NULL,  
		 territory_code    varchar(10)      NULL,  
		 carrier_code    varchar(20)      NULL,  
		 postal_code               varchar(10)         NULL,  
		 dest_zone_code    varchar(8)      NULL,  
		 ordered_dollars   decimal(20,8)      NULL,  
		 shippable_dollars   decimal(20,8)      NULL,  
		 shippable_margin_dollars  decimal(20,8)      NULL,  
		 ship_to    varchar(40)      NULL,  
		 so_priority_code  int       NULL    
	)   
	CREATE TABLE #so_soft_alloc_byline_tbl  
	(  
		 order_no  int    NOT NULL,  
		 order_ext int    NOT NULL,  
		 line_no   int    NOT NULL,  
		 part_no   varchar(30)   NOT NULL,
		 qty_override  decimal(20,8) DEFAULT (0) -- v2.2
	)  
	CREATE TABLE #so_alloc_err            
	(                                     
		 order_no  int,               
		 order_ext int,               
		 line_no   int,               
		 part_no   varchar(30),  
		 err_msg   varchar(255)      
	)   

	--------------------------------------------------------------------------------------------------  
	IF @status = 'V' -- Order has been voided  
	BEGIN               
		IF EXISTS(SELECT * FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext)  
		BEGIN  
  
			INSERT INTO #so_alloc_management (sel_flg, sel_flg2, prev_alloc_pct, curr_alloc_pct, curr_fill_pct,   
												order_no, order_ext, location, order_status, sch_ship_date, cust_code)  
			SELECT	0, -1, 0, 0, 0, order_no, ext, location, '', GETDATE(), ''
            FROM	orders_all (NOLOCK) 
            WHERE	order_no  = @order_no  
            AND		ext = @ext 
  
			SET    @con_no = 0  
			SELECT @con_no = consolidation_no FROM #sim_tdc_cons_ords (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext  
  
			EXEC sim_tdc_plw_so_unallocate_sp @user_id, @con_no  
  
			RETURN 0  
		END  
	END  
  
		 --------------  
	IF (@status >= 'R') RETURN 0 -- Exit out --  
     --------------  

	-- We need to delete any lines that are in the soft alloc table that are not tied to this order anymore.  
	-- I.e. line is deleted from the order  
	DELETE	FROM #sim_tdc_soft_alloc_tbl   
	WHERE	order_no   = @order_no    
	AND		order_ext  = @ext   
	AND		order_type = 'S' -- SCR 36078  
	AND		line_no NOT IN (SELECT line_no FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext)  
  
	DELETE	FROM #sim_tdc_pick_queue  
	WHERE	trans_type_no  = @order_no   
	AND		trans_type_ext = @ext   
	AND		line_no NOT IN (SELECT line_no FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext)  

	IF OBJECT_ID('tempdb..#so_alloc_management_Header') IS NOT NULL     
		DROP TABLE #so_alloc_management_Header       

	CREATE TABLE #so_alloc_management_Header                           
		(order_no int   NOT NULL,         
		order_ext int   NOT NULL,            
		location varchar(10) NOT NULL)                                                            

	IF OBJECT_ID('tempdb..#so_allocation_detail_view_Detail') IS NOT NULL     
		DROP TABLE #so_allocation_detail_view_Detail      

	CREATE TABLE #so_allocation_detail_view_Detail         
		(order_no        INT            NOT NULL,    
		order_ext       INT             NOT NULL,         
		location        VARCHAR(10)     NOT NULL,       
		line_no         INT             NOT NULL,       
		part_no         VARCHAR(30)     NOT NULL,       
		part_desc       VARCHAR(278)        NULL,         
		lb_tracking     CHAR(1)         NOT NULL,       
		qty_ordered     DECIMAL(24, 8)  NOT NULL,       
		qty_avail       DECIMAL(24, 8)  NOT NULL,       
		qty_picked      DECIMAL(24, 8)  NOT NULL,         
		qty_alloc       DECIMAL(24, 8)  NOT NULL,       
		avail_pct       DECIMAL(24,8)   NOT NULL,       
		alloc_pct       DECIMAL(24,8)   NOT NULL,       
		qty_to_alloc    INT                 NULL,         
		type_code       VARCHAR(10)         NULL,       
		from_line_no    INT                 NULL,       
		order_by_frame  INT                 NULL)       

	IF (object_id('tempdb..#so_pre_allocation_table') IS NOT NULL) 
		DROP TABLE #so_pre_allocation_table  

	CREATE TABLE #so_pre_allocation_table               
		(order_no             INT            NOT NULL,        
		order_ext            INT             NOT NULL,
		location             VARCHAR(10)     NOT NULL,
		part_no              VARCHAR(30)     NOT NULL,
		line_no              INT             NOT NULL,      
		pre_allocated_qty    DECIMAL(24,8)   NOT NULL)      

	CREATE INDEX #so_pre_allocation_table_idx1 
		ON #so_pre_allocation_table (order_no, order_ext, location, part_no,pre_allocated_qty)   

	IF OBJECT_ID('tempdb..#so_alloc_management_Match') IS NOT NULL 
		DROP TABLE #so_alloc_management_Match
	IF OBJECT_ID('tempdb..#so_allocation_detail_view_Match') IS NOT NULL 
		DROP TABLE #so_allocation_detail_view_Match
	IF OBJECT_ID('tempdb..#so_alloc_management_NO_match') IS NOT NULL 
		DROP TABLE #so_alloc_management_NO_match
	IF OBJECT_ID('tempdb..#so_allocation_detail_view_NO_match') IS NOT NULL 
		DROP TABLE #so_allocation_detail_view_NO_match

	SELECT  * INTO #so_alloc_management_Match         FROM #so_alloc_management_Header WHERE order_no < 0
	SELECT  * INTO #so_allocation_detail_view_Match   FROM #so_allocation_detail_view_Detail WHERE order_no < 0
	       
	SELECT  * INTO #so_alloc_management_NO_match       FROM #so_alloc_management_Header WHERE order_no < 0
	SELECT  * INTO #so_allocation_detail_view_NO_match FROM #so_allocation_detail_view_Detail WHERE order_no < 0
															
	EXEC CVO_sim_tdc_plw_so_alloc_management_sp @order_no, @ext

	IF EXISTS(SELECT * FROM tdc_plw_criteria_templates (NOLOCK) WHERE userid = @user_id AND frame_case_match = 1 ) -- Is frame_case_match set
	BEGIN

		EXEC dbo.CVO_frame_case_match_sp	
			 
		DELETE	a
		FROM	#so_alloc_management a
		LEFT JOIN #so_alloc_management_Match b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		WHERE	b.order_no IS NULL
		AND		b.order_ext IS NULL

		DELETE	a
		FROM	#so_allocation_detail_view_Detail a
		LEFT JOIN #so_alloc_management_Match b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		WHERE	b.order_no IS NULL
		AND		b.order_ext IS NULL


	END
	IF EXISTS(SELECT * FROM tdc_plw_criteria_templates (NOLOCK) WHERE userid = @user_id AND consolidate_shipment = 1 ) -- Is frame_case_match set
	BEGIN
		DELETE	a
		FROM	#so_alloc_management a
		JOIN	dbo.orders b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		JOIN	CVO_armaster_all c (NOLOCK)
		ON		b.cust_code = c.customer_code
		WHERE	c.address_type NOT IN (9,1)
		AND		ISNULL(c.consol_ship_flag, 0) = 0

		DELETE	a
		FROM	#so_allocation_detail_view_Detail a
		JOIN	dbo.orders b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		JOIN	CVO_armaster_all c (NOLOCK)
		ON		b.cust_code = c.customer_code
		WHERE	c.address_type NOT IN (9,1)
		AND		ISNULL(c.consol_ship_flag, 0) = 0

	
	END

	DECLARE @row_id			int,
			@last_row_id	int

	CREATE TABLE #ord_list_cursor (
		row_id		int IDENTITY(1,1),
		line_no		int,
		location	varchar(10),
		part_no		varchar(30),
		qty_ordered	decimal(20,8),
		qty_picked	decimal(20,8),
		cust_kit	char(1))

	INSERT	#ord_list_cursor (line_no, location, part_no, qty_ordered, qty_picked, cust_kit)
	SELECT	line_no, location, part_no, qty_ordered, qty_picked, 'N'                         
	FROM	#so_allocation_detail_view_Detail (NOLOCK)  
	WHERE	order_no  = @order_no   
    AND		order_ext = @ext  
	ORDER BY type_code asc 

	CREATE INDEX #ord_list_cursor_ind0 ON #ord_list_cursor ( row_id)

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@line_no = line_no, 
			@location = location, 
			@part_no = part_no, 
			@ordered = qty_ordered, 
			@shipped = qty_picked, 
			@cust_kit = cust_kit
	FROM	#ord_list_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
	
	WHILE (@@ROWCOUNT <> 0)
	BEGIN
  
		IF @cust_kit = 'Y'  
		BEGIN   
			SET @ordered = 0  
			SET @alloc_qty = 0  
			SET @shipped = 0  
		  
			--We will look in ord_list_kit to see if quantities have changed at each line  
			SELECT	@line_no   = ol.line_no,   
					@ordered   = SUM((ol.ordered * ol.qty_per)),   
					@alloc_qty = SUM(sa.qty),  
					@shipped   = (SELECT SUM(kit_picked)   
									FROM tdc_ord_list_kit tol (NOLOCK)   
									WHERE tol.order_no  = @order_no   
									AND tol.order_ext = @ext   
									AND line_no       = @line_no   
									AND location      = @location)  
			FROM	ord_list_kit       ol (NOLOCK)  
			JOIN	#sim_tdc_soft_alloc_tbl sa (NOLOCK)   
			ON		ol.order_no  = sa.order_no  
			AND		ol.order_ext = sa.order_ext  
			AND		ol.line_no   = sa.line_no  
			AND		ol.location  = sa.location  
			AND		ol.part_no   = sa.part_no  
			WHERE	ol.order_no  = @order_no   
			AND		ol.order_ext = @ext  
			AND		ol.line_no   = @line_no  
			AND		ol.location  = @location  
			GROUP BY ol.line_no  
		END  
		ELSE  
		BEGIN   
			SET @alloc_qty = 0  
  
			-- We will look in ord_list to see if quantities have changed at each line  
			SELECT	@alloc_qty = SUM(qty), @o=order_no, @e=order_ext, @l=location, @li=line_no, @p=part_no  
			FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)  
			WHERE	order_no  = @order_no  
			AND		order_ext = @ext  
			AND		line_no   = @line_no  
			AND		location  = @location  
			AND		part_no   = @part_no  
		    GROUP BY order_no, order_ext, location, line_no, part_no  
		END  
  
		IF @alloc_qty IS NULL SET @alloc_qty = 0  
  
		SET @pre_pack_flg = NULL --Jim on 11/12/2007   
    
		-----------------------------------------------------------    
		IF @ordered > (@alloc_qty + @shipped) -- Allocate line --  
		-----------------------------------------------------------  
		BEGIN   
			-- Get user template  
			SELECT	@alloc_type    = CASE dist_type   
										WHEN 'PrePack'   THEN 'PR'  
										WHEN 'ConsolePick'  THEN 'PT'  
										WHEN 'PickPack'  THEN 'PP'  
										WHEN 'PackageBuilder'  THEN 'PB' END,  
					@pre_pack_flg  = CASE dist_type   
										WHEN 'PrePack'   THEN 'Y'   
										ELSE 'N' END  
			FROM	tdc_plw_process_templates (NOLOCK)  
			WHERE	UserID     = @user_id  
			AND		template_code = @template_code  
			AND		location   = @location  
			AND		order_type = 'S'  
			AND		type       = 'one4one'  
  
			IF ISNULL(@template_code, '') = ''  
			BEGIN  
				DROP TABLE #ord_list_cursor
				RETURN -1  
			END  
  
			--do not allocate the line if no record found in tdc_plw_process_templates  
			IF @pre_pack_flg IS NULL CONTINUE --Jim on 11/12/2007   
  
			BEGIN TRAN  
  
			--------------------------------------------------------------------------------------------------------------  
			-- Update the cons_ords table and tdc_main  
			--------------------------------------------------------------------------------------------------------------   
			IF NOT EXISTS(SELECT 1 FROM tdc_cons_ords (NOLOCK) WHERE order_no  = @order_no AND order_ext = @ext AND location  = @location)  
			BEGIN  
        
				--------------------------------------------------------------------------------------------------------------  
				-- Create a new record in tdc_main and tdc_cons_ords  
				--------------------------------------------------------------------------------------------------------------  
  
			   -- get the next available cons number  
			   SELECT @next_con_no = MAX(consolidation_no) + 1 FROM #sim_tdc_main
  
			   -- our generic description and name   
			   SELECT @con_name = 'Ord ' +  CONVERT(VARCHAR(20), @order_no) + ' Ext ' + CONVERT(VARCHAR(4), @ext)   
			   SELECT @con_desc = 'Ord ' +  CONVERT(VARCHAR(20), @order_no) + ' Ext ' + CONVERT(VARCHAR(4), @ext)   
  
			   -- Insert the new generated con number in tdc_main and tdc_cons_ords  
			   INSERT INTO #sim_tdc_main (consolidation_no, consolidation_name, [description], order_type, created_by, creation_date, status, virtual_freight, pre_pack)   
			   VALUES (@next_con_no, @con_name,  @con_desc, 'S', @user_id , GETDATE(), 'O', 'N', @pre_pack_flg)  
    
			   INSERT INTO #sim_tdc_cons_ords (consolidation_no, order_no, order_ext,location, status, seq_no, print_count, order_type, alloc_type)  
			   VALUES (@next_con_no, @order_no, @ext, @location, 'O', 1 , 0, 'S', @alloc_type)             
			END   
			ELSE  
			BEGIN  
				UPDATE	#sim_tdc_cons_ords  
				SET		alloc_type = @alloc_type  
				WHERE	order_no   = @order_no  
				AND		order_ext  = @ext  
				AND		location   = @location  
	  
				UPDATE	#sim_tdc_main 
				SET		pre_pack = @pre_pack_flg   
				WHERE	consolidation_no = (SELECT consolidation_no  
											FROM #sim_tdc_cons_ords (NOLOCK) 
											WHERE order_no   = @order_no  
											AND order_ext  = @ext  
											AND location   = @location)  
			END  
  
			IF @@ERROR <> 0  
			BEGIN  

				DROP TABLE #ord_list_cursor
	  
				ROLLBACK TRAN  
				RETURN -2  
			END  
  
			TRUNCATE TABLE #so_alloc_err  
  

			EXEC CVO_sim_allocate_by_bin_group_sp  @user_id, @template_code, @order_no, @ext, @line_no, @part_no, 'Y',  
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1   	
							  
			IF EXISTS (SELECT * FROM #so_alloc_err)          
			BEGIN  
				DROP TABLE #ord_list_cursor
		  
				ROLLBACK TRAN  
				RETURN -3  
			END  
	  
			COMMIT TRAN 
		END  
  
		----------------------------------------------------------------------------------  
		IF @ordered < (@alloc_qty + @shipped) -- Unallocate and then re-allocate line --  
		----------------------------------------------------------------------------------  
		BEGIN   
			-----------------------------------------------------  
			-- Unallocate Line  
			-----------------------------------------------------  
			INSERT INTO #so_alloc_management (sel_flg, sel_flg2, prev_alloc_pct, curr_alloc_pct, curr_fill_pct,   
					order_no, order_ext, location, order_status, sch_ship_date, cust_code)  
			SELECT	0, -1, 0, 0, 0, order_no, ext, location, '', GETDATE(), ''  
            FROM	orders_all (NOLOCK) 
            WHERE	order_no  = @order_no  
            AND		ext = @ext
  
			INSERT INTO #so_soft_alloc_byline_tbl(order_no, order_ext, line_no, part_no)  
			VALUES (@order_no, @ext, @line_no, @part_no)  
  
			SET    @con_no = 0  
			SELECT @con_no = consolidation_no FROM #sim_tdc_cons_ords (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext  
  
			EXEC sim_tdc_plw_so_unallocate_sp @user_id, @con_no  
  
			-----------------------------------------------------  
			-- Re-allocate Line  
			-----------------------------------------------------  
			-- Get user template  
			SELECT	@alloc_type    = CASE dist_type   
										 WHEN 'PrePack'   THEN 'PR'  
										 WHEN 'ConsolePick'  THEN 'PT'  
										 WHEN 'PickPack'  THEN 'PP'  
										 WHEN 'PackageBuilder'  THEN 'PB' END,  
					@pre_pack_flg  = CASE dist_type   
										WHEN 'PrePack'   THEN 'Y'   
										ELSE 'N' END  
			FROM	tdc_plw_process_templates (NOLOCK)  
			WHERE	UserID     = @user_id  
			AND		template_code = @template_code  
			AND		location   = @location  
			AND		order_type = 'S'  
			AND		type       = 'one4one'  
  
			IF ISNULL(@template_code, '') = ''  
			BEGIN  

				DROP TABLE #ord_list_cursor
				RETURN -4  
			END  
  
			TRUNCATE TABLE #so_alloc_err  
  
			--do not allocate the line if no record found in tdc_plw_process_templates  
			IF @pre_pack_flg IS NULL CONTINUE --Jim on 11/12/2007   
  
			BEGIN TRAN  

			EXEC CVO_sim_allocate_by_bin_group_sp @user_id, @template_code, @order_no, @ext, @line_no, @part_no, 'Y',  
				   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1		

			IF EXISTS (SELECT * FROM #so_alloc_err)          
			BEGIN  
				DROP TABLE #ord_list_cursor
  
				ROLLBACK TRAN  
				RETURN -5  
			END  
  
			COMMIT TRAN  
  
		END  

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@line_no = line_no, 
				@location = location, 
				@part_no = part_no, 
				@ordered = qty_ordered, 
				@shipped = qty_picked, 
				@cust_kit = cust_kit
		FROM	#ord_list_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
   
	END  
  
	DROP TABLE #ord_list_cursor


	EXEC CVO_sim_allocate_by_bin_group_adjust_sp 1  

	IF EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
	BEGIN

		EXEC dbo.CVO_sim_Create_Frame_Bin_Moves_sp @order_no, @ext

		-- Code taken from CVO_ord_list_kit_trg
		CREATE TABLE #kit_table (
			row_id				int IDENTITY(1,1),
			location			varchar(10),
			part_no				varchar(30),
			order_no			int,
			order_ext			int,
			line_no				int,
			part_no_original	varchar(30),
			part_type			varchar(10))

		INSERT	#kit_table (location, part_no, order_no, order_ext, line_no, part_no_original, part_type)
		SELECT	a.location,
				a.part_no,
				a.order_no,
				a.order_ext,
				a.line_no,		
				a.part_no_original,
				b.part_type 
		FROM	CVO_ord_list_kit a
		JOIN	ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.replaced = 'S'
		AND		b.status IN ('N','A','C','Q')
		AND		a.order_no = @order_no
		AND		a.order_ext = @ext
		ORDER BY order_no, order_ext, line_no

	SET @last_row_id = 0
	SET @last_line = 0

	SELECT	TOP 1 @location = location,
			@part_no = part_no,
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no,
			@row_id = row_id,
			@part_no_original = part_no_original,
			@part_type = part_type
	FROM	#kit_table
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		IF (@part_type <> 'C')
		BEGIN
			-- Get the qty from the ord_list record for the frame
			SELECT	@qty = ordered
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
		
			-- Call custom routine to generate MGTB2B for sustituted component items
			EXEC dbo.CVO_sim_Create_Substitution_MGMB2B_Moves_sp @order_no, @order_ext, @line_no, @location, @part_no, @part_no, @part_no_original, @qty

		END
		ELSE
		BEGIN

			IF (@line_no > @last_line)
			BEGIN
				EXEC dbo.cvo_sim_process_custom_kit_sp @order_no, @order_ext, @line_no, 0
			END
			SET @last_line = @line_no

		END	

		SET @last_row_id = @row_id

		SELECT	TOP 1 @location = location,
				@part_no = part_no,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@row_id = row_id,
				@part_no_original = part_no_original,
				@part_type = part_type -- v1.4
		FROM	#kit_table
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	DROP TABLE #kit_table

	END
 
	RETURN 0  
END
GO
GRANT EXECUTE ON  [dbo].[sim_tdc_order_after_save] TO [public]
GO
