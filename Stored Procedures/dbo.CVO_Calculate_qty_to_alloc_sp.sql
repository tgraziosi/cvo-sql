SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_Calculate_qty_to_alloc_sp]    Script Date: 04/01/2010  *****
SED003 -- Case Part
Object:      Procedure CVO_Calculate_qty_to_alloc_sp  
Source file: CVO_Calculate_qty_to_alloc_sp.sql
Author:		 Jesus Velazquez
Created:	 04/05/2010
Function:    Calculates qty_to_alloc on every allocation screen refresh
Modified:    
Calls:    
Called by:   WMS74 -- Allocation Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.1 CB 12/13/2010 - If items on a backorder relate to a line on the original order then they do 
					not allocate when they should
v1.2 CB 12/13/2010 - Cases get allocated with the same qty as a frame, fix this for patterns
v1.3 CB 08/04/2011 - Fix for partially allocated items 
v1.4 CB 26/04/2011 - Change logic - Only checked frame qty when case existed
v1.5 CB 02/09/2011 - Add logic for auto POs
v1.6 CB 22/09/2011 - Performance
v1.7 CB 27/01/2012 - Orders not allocating in PWB
v1.9 CB 28/06/2012 - Cases not allocating due to the part has been changed on the backorder
v10.0 CB 23/05/2012 - Soft Allocation
v10.1 CB 04/10/2012 - When allocating by lot bin this needs to not override allocation qty
v10.2 CB 11/10/2012 - Fix issue - need to take into account the quantity already allocated
v10.3 CB 18/12/2012 - Deal with pre-soft alloc
v10.4 CB 05/06/2013 - Issue #1297 - Deal with polarized items
v10.5 CB 07/06/2013 - Issue #1289 - Frame/case relationship at order entry
v10.6 CB 18/06/2013 - Fix for when order is partially picked and then unallocated and reallocated - cases do not allocate
v10.7 CB 26/01/2016 - #1581 2nd Polarized Option
v10.8 CB 23/08/2016 - CVO-CF-49 - Dynamic Custom Frames
v10.9 CB 30/05/2017 - #1628 Items added after picked 
*/
CREATE PROCEDURE [dbo].[CVO_Calculate_qty_to_alloc_sp] AS
BEGIN				  	
	DECLARE @order_no				INT,
			@order_ext				INT, 
			@location				VARCHAR(30)--,
			-- v10.7 @polarized				VARCHAR(10)
		
-- v10.7	SET @polarized = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

	-- v1.9
	UPDATE	a
	SET		part_no = b.part_no
	FROM	CVO_qty_to_alloc_tbl a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.part_no <> b.part_no
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	-- v10.0
	-- Create working tables
	CREATE TABLE #splits (
		order_no		int,
		order_ext		int,
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		has_case		int,
		has_pattern		int,
		has_polarized	int,
		case_part		varchar(30),
		pattern_part	varchar(30),
		polarized_part	varchar(30),
		quantity		decimal(20,8),
		part_type		varchar(20),
		alloc_qty		decimal(20,8),
		auto_po			smallint,
		from_line_no	int) -- v10.4

	CREATE TABLE #part_splits (
		part_no		varchar(30),
		quantity	decimal(20,8),
		diff		decimal(20,8))

	DECLARE selected_orders_cur CURSOR FOR
	SELECT	order_no, order_ext, location FROM #so_alloc_management_Header
	
	OPEN selected_orders_cur

	FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--BEGIN SED009 -- Pick Ticket Printing   
		--JVM 08/23/2010  
		-- v1.6
		UPDATE  #so_alloc_management   
		SET		total_pieces  = (SELECT COUNT(*)    FROM #so_allocation_detail_view  WHERE order_no = @order_no AND order_ext = @order_ext AND qty_alloc > 0),
				lowest_bin_no = (SELECT ISNULL(MIN(bin_no),'') FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		WHERE	order_no  = @order_no	AND 
				order_ext = @order_ext
		--END   SED009 -- Pick Ticket Printing

		DELETE	#splits
		DELETE	#part_splits

		-- Populate working tables
		INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
							pattern_part, polarized_part, quantity, part_type, alloc_qty, auto_po, from_line_no) -- v10.4
		SELECT	a.order_no,
				a.order_ext,
				a.line_no,
				a.location,
				a.part_no,
				CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
				CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
				CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
	-- v10.5	CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
				CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END,
	-- v10.5	CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
				CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END,
-- v10.7		CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized ELSE '' END,
				CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v10.7
				a.ordered, 
				CASE WHEN d.status = 'C' THEN 'KIT' ELSE d.type_code END, -- v10.8
				0.0,
				ISNULL(a.create_po_flag,0),
				ISNULL(a.cust_po,0) -- v10.4
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
	-- v10.5	JOIN	inv_master_add c (NOLOCK)
	-- v10.5	ON		a.part_no = c.part_no
		LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v10.5
		ON		a.order_no = fc.order_no -- v10.5
		AND		a.order_ext = fc.order_ext -- v10.5
		AND		a.line_no = fc.line_no -- v10.5
		JOIN	inv_master d (NOLOCK)
		ON		a.part_no = d.part_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.shipped < a.ordered -- v10.9
		ORDER BY a.line_no

		-- if the data is an order since soft allocation was added then the #splits table is correct
		-- if the data is from a prior order then we need to update te splits table to mimic the new data
		IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND ISNULL(from_line_no,0) <> 0)
		BEGIN
			UPDATE	a
			SET		case_part = c.part_no,
					has_case = 1
			FROM	#splits a	
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.from_line_no
			JOIN	ord_list c (NOLOCK)
			ON		b.order_no = c.order_no
			AND		b.order_ext = c.order_ext
			AND		b.line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.is_case = 1

			UPDATE	a
			SET		pattern_part = c.part_no,
					has_pattern = 1
			FROM	#splits a	
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.from_line_no
			JOIN	ord_list c (NOLOCK)
			ON		b.order_no = c.order_no
			AND		b.order_ext = c.order_ext
			AND		b.line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.is_pattern = 1

			UPDATE	a
			SET		polarized_part = c.part_no,
					has_polarized = 1
			FROM	#splits a	
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.from_line_no
			JOIN	ord_list c (NOLOCK)
			ON		b.order_no = c.order_no
			AND		b.order_ext = c.order_ext
			AND		b.line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.is_polarized = 1
		END

		-- v10.1 Start
		IF OBJECT_ID('tempdb..#plw_alloc_by_lot_bin') IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM #plw_alloc_by_lot_bin) -- This mean that this routine has been called as a refresh after allocating by lot bin
			BEGIN
				DELETE	CVO_qty_to_alloc_tbl 
				WHERE	order_no  = @order_no
				AND		order_ext = @order_ext
				AND		location  = @location
			END
		END
		ELSE
		BEGIN
			DELETE	CVO_qty_to_alloc_tbl 
			WHERE	order_no  = @order_no
			AND		order_ext = @order_ext
			AND		location  = @location
		END
		-- v10.1 End

		-- Get the allocated quantities
		UPDATE	#splits
		SET		alloc_qty = (CASE WHEN a.auto_po = 1 THEN 0 ELSE 
-- v10.2							CASE WHEN b.qty_alloc = 0 THEN (b.qty_avail + b.qty_alloc) - b.qty_picked ELSE b.qty_alloc END END)
								(b.qty_avail + b.qty_alloc) - b.qty_picked END) -- v10.2
		FROM	#splits a
		JOIN	#so_allocation_detail_view_Detail b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		AND		a.part_no = b.part_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext

		-- v10.8 Start
		UPDATE	#splits
		SET		alloc_qty = quantity
		WHERE	part_type = 'KIT'
		AND		order_no = @order_no
		AND		order_ext = @order_ext
		-- v10.8 End

		-- v10.6 alloc_qty < 0 when partially picked
		UPDATE	#splits
		SET		alloc_qty = 0 
		WHERE	alloc_qty < 0

		-- Get the quantities for cases, patterns and polarized adjusted for non allocated frames
		INSERT	#part_splits (part_no, quantity, diff)
		SELECT	case_part,
				SUM(alloc_qty),
				SUM(quantity - alloc_qty) 
		FROM	#splits
		WHERE	case_part <> ''
		AND		order_no = @order_no
		AND		order_ext = @order_ext
		GROUP BY case_part

		INSERT	#part_splits (part_no, quantity, diff)
		SELECT	pattern_part,
				SUM(alloc_qty),
				SUM(quantity - alloc_qty)
		FROM	#splits
		WHERE	pattern_part <> ''
		AND		order_no = @order_no
		AND		order_ext = @order_ext
		GROUP BY pattern_part

		INSERT	#part_splits (part_no, quantity, diff)
		SELECT	polarized_part,
				SUM(alloc_qty),
				SUM(quantity - alloc_qty)
		FROM	#splits
		WHERE	polarized_part <> ''
		AND		order_no = @order_no
		AND		order_ext = @order_ext
		GROUP BY polarized_part


		-- v10.3 Start
		IF NOT EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND ISNULL(from_line_no,0) <> 0)
		BEGIN
	
			-- Adjust the quantities to allocate
			UPDATE	#splits
			SET		alloc_qty = a.quantity - b.diff
			FROM	#splits a 
			JOIN	#part_splits b
			ON		a.part_no = b.part_no
			WHERE	case_part = ''
			AND		pattern_part = ''
			AND		polarized_part = ''
			AND		a.order_no = @order_no
			AND		a.order_ext = @order_ext
-- v10.7	AND		a.part_no <> @polarized -- v10.4	
			AND		a.part_no NOT IN (SELECT part_no FROM cvo_polarized_vw) -- v10.7

	
		END
		-- v10.3 End



		-- v10.4 Start
		UPDATE	a
		SET		alloc_qty = b.alloc_qty
		FROM	#splits a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.part_no = b.polarized_part
		AND		a.from_line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.polarized_part = ''
		AND		b.polarized_part <> ''
		AND		b.alloc_qty = 0
		-- v10.4 End


		-- Update back to the processing table
		UPDATE	a
		SET		qty_to_alloc = b.alloc_qty
		FROM	#so_allocation_detail_view_Detail a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		AND		a.part_no = b.part_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext

		-- v10.8 Start
		UPDATE	a
		SET		qty_to_alloc = a.qty_avail
		FROM	#so_allocation_detail_view_Detail a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		AND		b.part_type = 'KIT'
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		-- v10.8 End

		-- v10.1 Start
		IF OBJECT_ID('tempdb..#plw_alloc_by_lot_bin') IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM #plw_alloc_by_lot_bin) -- This mean that this routine has been called as a refresh after allocating by lot bin
			BEGIN
				-- Populate the CVO_qty_to_alloc_tbl table
				INSERT	CVO_qty_to_alloc_tbl (order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc )  
				SELECT	order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc  
				FROM	#so_allocation_detail_view_Detail  
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
			END	
		END
		ELSE
		BEGIN
	
			-- Populate the CVO_qty_to_alloc_tbl table
			INSERT	CVO_qty_to_alloc_tbl (order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc )  
			SELECT	order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc  
			FROM	#so_allocation_detail_view_Detail  
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

		END
		-- v10.1 End

		-- v10.3 Start
		IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND ISNULL(from_line_no,0) <> 0)
		BEGIN
			UPDATE	a
			SET		qty_to_alloc = c.qty_to_alloc
			FROM	#so_allocation_detail_view_Detail a
			JOIN	cvo_ord_list b (NOLOCK) 
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			JOIN	#so_allocation_detail_view_Detail c
			ON		b.order_no = c.order_no
			AND		b.order_ext = c.order_ext
			AND		b.from_line_no = c.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.from_line_no <> 0
			AND		c.qty_to_alloc < a.qty_to_alloc

			UPDATE	a
			SET		qty_to_alloc = b.qty_to_alloc
			FROM	CVO_qty_to_alloc_tbl a
			JOIN	#so_allocation_detail_view_Detail b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			JOIN	cvo_ord_list c (NOLOCK)
			ON		b.order_no = c.order_no
			AND		b.order_ext = c.order_ext
			AND		b.line_no = c.line_no										
			WHERE	c.from_line_no <> 0
			AND		a.qty_to_alloc <> b.qty_to_alloc

		END
		-- v10.3	

--		select * into temp_so_allocation_detail_view_Detail	from #so_allocation_detail_view_Detail


		FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location
	END
	CLOSE      selected_orders_cur	
	DEALLOCATE selected_orders_cur

	DELETE FROM #so_allocation_detail_view 	
	INSERT INTO #so_allocation_detail_view SELECT * FROM #so_allocation_detail_view_Detail

	-- v10.1
	IF OBJECT_ID('tempdb..#plw_alloc_by_lot_bin') IS NOT NULL
		TRUNCATE TABLE #plw_alloc_by_lot_bin


END
GO

GRANT EXECUTE ON  [dbo].[CVO_Calculate_qty_to_alloc_sp] TO [public]
GO
