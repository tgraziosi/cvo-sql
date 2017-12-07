SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CVO_sim_tdc_plw_so_alloc_management_sp]	@order_no_  INT,  
															@order_ext_ INT  
AS
BEGIN   
	-- NOTE: Based on CVO_tdc_plw_so_alloc_management_sp v11.0 - All changes must be kept in sync
   
	DECLARE @order_no							INT,    
			@order_ext							INT,    
			@location							VARCHAR(10),    
			@part_no							VARCHAR(30),    
			@line_no							INT,    
			@lb_tracking						CHAR(1),    
			@part_type							CHAR(1)    
	    	    
	DECLARE @qty_in_stock						DECIMAL(20,8),    
			@qty_ordered_for_part_line_no		DECIMAL(24,8),    
			@qty_alloc_for_part_total			DECIMAL(20,8),     
			@qty_alloc_for_part_line_no			DECIMAL(20,8),    
			@qty_avail_for_part_total			DECIMAL(20,8),    
			@qty_avail_for_part_line_no			DECIMAL(24,8),    
			@qty_pre_allocated_total			DECIMAL(20,8),    
			@qty_pre_alloc_for_part_on_order	DECIMAL(20,8),    
			@qty_picked_for_part_line_no		DECIMAL(24,8),    
			@qty_needed_for_part_line_no		DECIMAL(24,8)   
	    
	DECLARE @alloc_pct_for_part_line_no			DECIMAL(20,2),    
			@avail_pct_for_part_line_no			DECIMAL(20,2)    

	DECLARE	@row_id				int,
			@last_row_id		int,
			@line_row_id		int,
			@last_line_row_id	int

	DECLARE	@qty_alloc_sa	decimal(20,8),
			@max_soft_alloc	int 

	DECLARE	@qty_sa_alloc	decimal(20,8) 

	INSERT INTO #so_alloc_management_Header (order_no, order_ext, location) SELECT order_no, ext, location FROM orders_all (NOLOCK) WHERE order_no = @order_no_ AND ext = @order_ext_

	 -- Now we'll loop through the Sales Orders and populate the #so_allocation_detail_view_Detail,    
	 -- and calculate all the data we need for the #so_alloc_management_Header table    
	     
	 ----------------------------------------------------------------------------------------------------------    
	 -- selected_detail_cursor declaration is being executed as a string so the order by clause that is sent by  --    
	 -- the VB app can be applied this process is important in that it will determine what orders get rights --    
	 -- to the inventory first.                                                                              --    
	 ----------------------------------------------------------------------------------------------------------    
	
	CREATE TABLE #excluded_bins (location varchar(10), bin_no varchar(20)) 
	CREATE INDEX #ind0 ON #excluded_bins(location, bin_no) 

	INSERT #excluded_bins SELECT location, bins FROM dbo.f_get_excluded_bins(2)

	CREATE TABLE #selected_detail_cursor (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		location		varchar(10))

	CREATE TABLE #detail_cursor (
		line_row_id		int IDENTITY(1,1),
		part_no			varchar(30), 
		line_no			int, 
		qty_ordered		decimal(20,8), 
		qty_picked		decimal(20,8), 
		lb_tracking		char(1))

	INSERT	#selected_detail_cursor (order_no, order_ext, location)
	SELECT	order_no, order_ext, location    
	FROM	#so_alloc_management_Header

	CREATE INDEX #selected_detail_cursor_ind0 ON #selected_detail_cursor(row_id)
	CREATE INDEX #detail_cursor_ind0 ON #detail_cursor(line_row_id)

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location
	FROM	#selected_detail_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
	     
	 ------------------------------------------------------------------------------------------------------------------------------------    
	  -- Now we'll get all the data we can get for the #so_allocation_detail_view_Detail table.    
	  -- Later we'll update the the feilds that have to be calculated.    
		INSERT INTO #so_allocation_detail_view_Detail (order_no, order_ext, location, line_no, part_no, part_desc, lb_tracking,     
															qty_ordered, qty_avail, qty_picked, qty_alloc, avail_pct, alloc_pct)    
		SELECT	order_no, order_ext, location, line_no, part_no, [description], lb_tracking, ordered * conv_factor, 0, shipped * conv_factor, 0, 0, 0    
		FROM	ord_list (NOLOCK)    
		WHERE	order_no  = @order_no    
		AND		order_ext = @order_ext    
		AND		location  = @location    
		AND		(create_po_flag IS NULL OR create_po_flag <> 1)    
		AND		part_type != 'C'    
		AND		part_type != 'V' 
		AND		part_type IS NOT NULL    
		UNION -- JVM allow kit allocation 
		SELECT	ol.order_no, ol.order_ext, ol.location, ol.line_no, olk.part_no, olk.[description],   
				olk.lb_tracking, olk.ordered * olk.qty_per * olk.conv_factor, 0, olk.shipped * olk.qty_per * olk.conv_factor, 0, 0, 0  
		FROM	ord_list ol(NOLOCK),  
				ord_list_kit olk (NOLOCK)  
	    WHERE	ol.order_no  = @order_no  
		AND		ol.order_ext = @order_ext  
		AND		ol.location  = @location  
		AND		ol.order_no  = olk.order_no   
		AND		ol.order_ext = olk.order_ext   
		AND		ol.location  = olk.location   
		AND		ol.line_no   = olk.line_no  
		AND		ol.part_type = 'C'

		IF OBJECT_ID('tempdb..#line_exclusions') IS NOT NULL
		BEGIN
     		DELETE	a
			FROM	#so_allocation_detail_view_Detail a
			JOIN	#line_exclusions b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no   
		END


		IF OBJECT_ID('tempdb..#backorder_processing_allocation') IS NOT NULL
		BEGIN
			DELETE		a
			FROM		#so_allocation_detail_view_Detail a
			LEFT JOIN	#backorder_processing_allocation b
			ON			a.order_no = b.order_no
			AND			a.order_ext = b.ext
			AND			a.line_no = b.line_no   
			WHERE		b.order_no IS NULL

			-- Now update qtys for frame
			UPDATE	a
			SET		qty_ordered = b.qty + ISNULL(b.allocated,0)
			FROM	#so_allocation_detail_view_Detail a
			JOIN	#backorder_processing_allocation b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.ext
			AND		a.line_no = b.line_no 
			WHERE	b.is_frame = 1 

		END
		
		-- Backorder Processing - PO: Remove order lines not being processed by the job
		IF OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NOT NULL
		BEGIN
			DELETE		a
			FROM		#so_allocation_detail_view_Detail a
			LEFT JOIN	#backorder_processing_po_allocation_summary b
			ON			a.order_no = b.order_no
			AND			a.order_ext = b.ext
			AND			a.line_no = b.line_no   
			WHERE		b.order_no IS NULL

			-- Now update qtys for frame
			UPDATE	a
			SET		qty_ordered = b.qty + ISNULL(b.allocated,0)
			FROM	#so_allocation_detail_view_Detail a
			JOIN	#backorder_processing_po_allocation_summary b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.ext
			AND		a.line_no = b.line_no 
			WHERE	b.is_frame = 1 

		END

		UPDATE	a
		SET		type_code = CASE WHEN b.type_code IN ('SUN','FRAME') THEN '0' ELSE '1' END 
		FROM	#so_allocation_detail_view_Detail a
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no

		 SET @max_soft_alloc = 0    
		     
		 SELECT @max_soft_alloc = MAX(soft_alloc_no)    
		 FROM #sim_cvo_soft_alloc_hdr (NOLOCK)    
		 WHERE order_no = @order_no    
		 AND  order_ext = @order_ext    
		 AND  status IN (0,1,-1)    
		
		DELETE #detail_cursor

		INSERT #detail_cursor (part_no, line_no, qty_ordered, qty_picked, lb_tracking)
		SELECT	part_no, line_no, qty_ordered, qty_picked, lb_tracking     
		FROM	#so_allocation_detail_view_Detail     
		WHERE	order_no  = @order_no    
		AND		order_ext = @order_ext    
		AND		location  = @location    
		ORDER BY line_no    

		SET @last_line_row_id = 0
		SET @qty_ordered_for_part_line_no = 0
		SET @qty_picked_for_part_line_no = 0

		SELECT	TOP 1 @line_row_id = line_row_id,
				@part_no = part_no, 
				@line_no = line_no, 
				@qty_ordered_for_part_line_no = qty_ordered, 
				@qty_picked_for_part_line_no = qty_picked, 
				@lb_tracking = lb_tracking     
		FROM	#detail_cursor
		WHERE	line_row_id > @last_line_row_id
		ORDER BY line_row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			------------------------------------------------------------------------------------------------------------------    
			--  Get part type    
			------------------------------------------------------------------------------------------------------------------    
			SELECT	@part_type = part_type    
			FROM	ord_list (NOLOCK)    
			WHERE	order_no  = @order_no     
			AND		order_ext = @order_ext    
			AND		line_no   = @line_no     
		     
			------------------------------------------------------------------------------------------------------------------    
			--  Get allocated qty and qty to be allocated for the part / line_no    --    
			------------------------------------------------------------------------------------------------------------------    
			SELECT @qty_alloc_for_part_line_no = 0    
			IF @part_type NOT IN ('M', 'V')    
			BEGIN    
				--  Get allocated qty for the part_no/line_no on the order remove any reference to cross dock bins    
				SELECT	@qty_alloc_for_part_line_no = ISNULL((SELECT SUM(qty)    
				FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)    
				WHERE	order_no   = @order_no    
				AND		order_ext  = @order_ext    
				AND		order_type = 'S'    
				AND		location   = @location    
				AND		line_no    = @line_no    
				AND		part_no    = @part_no    
				AND		((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))    
				GROUP BY location), 0)    
			END    
			ELSE    
			BEGIN    
				SELECT @qty_alloc_for_part_line_no = @qty_ordered_for_part_line_no    
			END    
		     
			------------------------------------------------------------------------------------------------------------------    
			--  Get qty that is needed for the part_no/line_no on the order     --    
			------------------------------------------------------------------------------------------------------------------       
			SELECT	@qty_needed_for_part_line_no = ISNULL(@qty_ordered_for_part_line_no, 0) - ISNULL(@qty_picked_for_part_line_no,  0) -     
					 ISNULL(@qty_alloc_for_part_line_no,   0)    

			IF @qty_needed_for_part_line_no IS NULL     
				SELECT @qty_needed_for_part_line_no = 0    
			--------------------------------------------------------------------------------------------------------------------------    
		     
			-- Get In Stock qty for the part_no from all the BINs except the receipt BINs    
			SELECT	@qty_in_stock = 0    
		    
			--  Get allocated qty for the part_no for all the orders. Remove any reference to cross dock BINs.               
			SELECT @qty_alloc_for_part_total = 0    
		    
			IF @lb_tracking = 'N'     
			BEGIN    
				SELECT @qty_in_stock = 0    
				SELECT	@qty_in_stock = in_stock     
				FROM	inventory (NOLOCK)     
				WHERE	part_no = @part_no     
				AND		location = @location    
		    
				SELECT	@qty_in_stock = ISNULL(@qty_in_stock, 0) - ISNULL((SELECT SUM(pick_qty - used_qty)     
				FROM	tdc_wo_pick (NOLOCK)    
				WHERE	part_no = @part_no     
				AND		location = @location), 0)    
		    
				SELECT	@qty_alloc_for_part_total = ISNULL((SELECT SUM(qty)    
				FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)    
				WHERE	location = @location    
				AND		part_no  = @part_no), 0)    
		    
			END    
			ELSE       
			BEGIN    
				SELECT	@qty_in_stock = ISNULL(( SELECT SUM(qty)     
				FROM	lot_bin_stock  a (NOLOCK),     
						tdc_bin_master b (NOLOCK)     
				WHERE	a.location = @location     
				AND		a.part_no  = @part_no                     
				AND		a.bin_no   = b.bin_no     
				AND		a.location = b.location     
				AND		b.usage_type_code IN ('OPEN', 'REPLENISH')  
			    AND		a.bin_no NOT IN (SELECT bin_no FROM #excluded_bins WHERE location = @location)
				GROUP BY a.part_no), 0)   

				SELECT	@qty_alloc_for_part_total = ISNULL((SELECT SUM(a.qty)    
				FROM	#sim_tdc_soft_alloc_tbl a(NOLOCK),    
						tdc_bin_master b(NOLOCK)    
				WHERE	a.location   = @location    
				AND		a.part_no    = @part_no    
				AND		a.location   = b.location    
				AND		a.bin_no     = b.bin_no    
				AND		(a.lot_ser != 'CDOCK' AND a.bin_no != 'CDOCK')    
				AND		b.usage_type_code IN ('OPEN', 'REPLENISH')    
				GROUP BY a.location ), 0)    
			END    
		    
			-- Get pre-allocated qty for the part on all the Sales Orders    
			SELECT	@qty_pre_allocated_total = ISNULL((SELECT SUM(pre_allocated_qty)    
			FROM	#so_pre_allocation_table     
			WHERE	part_no  = @part_no    
			AND		location = @location    
			GROUP BY location) , 0)    

			-- v1.1 Start
			IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @part_no AND type_code = 'CASE')
			BEGIN
				SET @qty_alloc_sa = 0
			END
			ELSE
			BEGIN		     
				SELECT @qty_alloc_sa = ISNULL((SELECT SUM(a.quantity)  
						FROM #sim_cvo_soft_alloc_det a (NOLOCK)   
						LEFT JOIN #selected_detail_cursor b
						ON a.order_no = b.order_no
						AND	a.order_ext = b.order_ext
					   WHERE a.part_no  = @part_no  
						 AND a.location = @location
						 AND a.soft_alloc_no < @max_soft_alloc
						 AND a.status IN (0,1,-1)
						  AND b.order_no IS NULL
					  GROUP BY a.location) , 0) 

				SELECT @qty_sa_alloc = ISNULL((SELECT SUM(b.qty)  
							FROM	#sim_cvo_soft_alloc_det a (NOLOCK)   
							JOIN	#sim_tdc_soft_alloc_tbl b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.order_ext = b.order_ext
							AND		a.line_no = b.line_no
							AND		a.part_no = b.part_no
							WHERE	a.part_no  = @part_no  
							AND		a.location = @location
							AND		a.soft_alloc_no < @max_soft_alloc
							AND		a.status IN (0,1,-1)
							GROUP BY a.location) , 0) 

				SELECT @qty_alloc_sa = @qty_alloc_sa - ISNULL(@qty_sa_alloc,0)
			END
			-- v1.1 End

		   SELECT @qty_pre_allocated_total = @qty_pre_allocated_total + ISNULL(@qty_alloc_sa,0)

			------------------------------------------------------------------------------------------------------------------    
			--  Calculate total available qty for the part        --    
			------------------------------------------------------------------------------------------------------------------    
			SELECT @qty_avail_for_part_total = 0    
			SELECT	@qty_avail_for_part_total = ISNULL(@qty_in_stock,       0) -     
					ISNULL(@qty_alloc_for_part_total, 0) -     
					ISNULL(@qty_pre_allocated_total,  0)    


		    -- v10.5 Start
			IF (@qty_avail_for_part_total < 0)
				SET @qty_avail_for_part_total = 0
			-- v10.5 End

			-- Get pre-allocated qty for the part on the current order    
			SELECT	@qty_pre_alloc_for_part_on_order = ISNULL((SELECT SUM(pre_allocated_qty)    
			FROM	#so_pre_allocation_table     
			WHERE	order_no  = @order_no    
			AND		order_ext = @order_ext    
			AND		location  = @location    
			AND		part_no   = @part_no    
			GROUP BY location), 0)    

	    
			------------------------------------------------------------------------------------------------------------------    
			--  Calculate available qty for the part / line_no on the order     --    
			------------------------------------------------------------------------------------------------------------------    
			SELECT @qty_avail_for_part_line_no = 0    
		     
			IF ISNULL(@qty_avail_for_part_total, 0) < ISNULL(@qty_needed_for_part_line_no, 0)    
				SELECT @qty_avail_for_part_line_no = ISNULL(@qty_avail_for_part_total, 0)    
			ELSE    
				SELECT @qty_avail_for_part_line_no = ISNULL(@qty_needed_for_part_line_no, 0)    
		    
			------------------------------------------------------------------------------------------------------------------    
			--  Calculate current allocated % for the part_no / line_no on the order    --    
			------------------------------------------------------------------------------------------------------------------    
			SELECT @alloc_pct_for_part_line_no = 0    

			------------------------------------------------------------------------------------------------------------------    
			--  Calculate currently available % for the part_no/line_no on the order    --    
			------------------------------------------------------------------------------------------------------------------    
			SELECT @avail_pct_for_part_line_no = 0           
		     
			------------------------------------------------------------------------------------------------------------------    
			--  Make final update to the #so_allocation_detail_view_Detail table     --    
			------------------------------------------------------------------------------------------------------------------        


			UPDATE	#so_allocation_detail_view_Detail    
			SET		qty_avail  = CASE WHEN @qty_avail_for_part_line_no <= 0 THEN 0    
										ELSE @qty_avail_for_part_line_no END,    
					qty_picked = @qty_picked_for_part_line_no,    
					avail_pct  = CASE WHEN @avail_pct_for_part_line_no >= 100 THEN 100    
										WHEN @avail_pct_for_part_line_no <= 0 THEN 0    
										ELSE  @avail_pct_for_part_line_no END,    
					alloc_pct  = CASE WHEN @alloc_pct_for_part_line_no >= 100 THEN 100    
										ELSE  @alloc_pct_for_part_line_no END    
			WHERE	order_no   = @order_no     
			AND		order_ext  = @order_ext    
			AND		location   = @location    
			AND		part_no    = @part_no    
			AND		line_no   = @line_no    
		        
			SET @last_line_row_id = @line_row_id
			SET @qty_ordered_for_part_line_no = 0
			SET @qty_picked_for_part_line_no = 0

			SELECT	TOP 1 @line_row_id = line_row_id,
					@part_no = part_no, 
					@line_no = line_no, 
					@qty_ordered_for_part_line_no = qty_ordered, 
					@qty_picked_for_part_line_no = qty_picked, 
					@lb_tracking = lb_tracking     
			FROM	#detail_cursor
			WHERE	line_row_id > @last_line_row_id
			ORDER BY line_row_id ASC


		END    
	      

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location
		FROM	#selected_detail_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END    
	     
	DROP TABLE #selected_detail_cursor
	DROP TABLE #detail_cursor

	-- Now update qtys available for cases to include what is already allocated
	IF OBJECT_ID('tempdb..#backorder_processing_allocation') IS NOT NULL
	BEGIN
		UPDATE	a
		SET		qty_avail = qty_avail + ISNULL(b.allocated,0)
		FROM	#so_allocation_detail_view_Detail a
		JOIN	#backorder_processing_allocation b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		AND		a.line_no = b.line_no 
		WHERE	b.is_case = 1  
	
	END 

	-- POs: Now update qtys available for cases to include what is already allocated
	IF OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NOT NULL
	BEGIN
		UPDATE	a
		SET		qty_avail = qty_avail + ISNULL(b.allocated,0)
		FROM	#so_allocation_detail_view_Detail a
		JOIN	#backorder_processing_po_allocation_summary b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		AND		a.line_no = b.line_no 
		WHERE	b.is_case = 1  
	
	END 
	 
	EXEC CVO_sim_Calculate_qty_to_alloc_eBO_sp @order_no_, @order_ext_ 
 
	EXEC CVO_sim_validate_promo_kits_sp @order_no_, @order_ext_

	EXEC CVO_validate_pop_gifts_sp @order_no_, @order_ext_

END
GO
GRANT EXECUTE ON  [dbo].[CVO_sim_tdc_plw_so_alloc_management_sp] TO [public]
GO
