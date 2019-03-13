SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_calculate_packaging_sp]	@order_no int, 
											@order_ext int,
											@order_type char(1)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@order_qty				decimal(20,8),
			@box_id					int,
			@box_type				varchar(20),
			@box_capacity			int,
			@remaining_qty			decimal(20,8),
			@tmp_remaining_qty		decimal(20,8),
			@box_remainder			decimal(20,8),
			@box_type_chk			varchar(20),
			@box_capacity_chk		int,
			@box_type_chk_up		varchar(20),
			@box_capacity_chk_up	int,
			@row_id					int,
			@line_no				int,
			@part_no				varchar(30),
			@alloc_qty				decimal(20,8),
			@packed_qty				decimal(20,8),
			@ord_qty				decimal(20,8),
			@alloc_order_no			int,
			@alloc_order_ext		int,
			@next					int,
			@cons_no				int,
			@kit_item				char(1),
			@result_id				int, -- v1.2
			@pack_row_id			int -- v1.2

	-- WORKING TABLES
	CREATE TABLE #allocations (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int,
		cons_no		int,
		line_no		int,
		part_no		varchar(30),
		bin_no		varchar(20), -- v1.3
		ord_qty		decimal(20,8),
		alloc_qty	decimal(20,8),
		packed_qty	decimal(20,8),
		kit_item	char(1))

	CREATE TABLE #allocation_lines (
		order_no	int,
		order_ext	int,
		cons_no		int,
		line_no		int,
		part_no		varchar(30),
		bin_no		varchar(20), -- v1.3
		ord_qty		decimal(20,8),
		alloc_qty	decimal(20,8),
		kit_item	char(1))

	-- v1.2 Start
	CREATE TABLE #pack_results (
		row_id			int IDENTITY(1,1),
		result_id		int,
		box				varchar(10),
		box_capacity	int,
		qty				decimal(20,8),
		fill_perc		decimal(20,8))
	-- v1.2 End

	-- PROCESSING
	-- v1.1 Start
	IF NOT EXISTS (SELECT 1 FROM dbo.tdc_pkg_master (NOLOCK) WHERE pm_int_udef_f <> 0)
	BEGIN
		RETURN
	END
	-- v1.1 End

	SET @cons_no = 0

	IF (@order_type = 'S')
	BEGIN
		-- Check if consolidated
		IF EXISTS (SELECT 1 FROM dbo.cvo_masterpack_consolidation_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			SELECT	@cons_no = consolidation_no
			FROM	dbo.cvo_masterpack_consolidation_det (NOLOCK) 
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext
		END
	END

	-- Remove any existing data
	IF (@cons_no = 0)
	BEGIN
		DELETE	dbo.cvo_pre_packaging
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
	END
	ELSE
	BEGIN	
		-- v1.5 Start
		DELETE	dbo.cvo_pre_packaging
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext	

--		DELETE	a
--		FROM	dbo.cvo_pre_packaging a
--		JOIN	dbo.cvo_masterpack_consolidation_det b (NOLOCK)
--		ON		a.order_no = b.order_no
--		AND		a.order_ext = b.order_ext
		-- v1.5 End
	END	

	-- Get the allocated quantities dealing with custom kits
	IF (@order_type = 'S')
	BEGIN
		IF (@cons_no = 0)
		BEGIN
			INSERT	#allocation_lines (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, kit_item) -- v1.3
			SELECT	DISTINCT a.order_no, a.order_ext, 0, a.line_no, CASE b.part_type WHEN 'C' THEN  b.part_no ELSE a.part_no END, a.bin_no,  -- v1.3
					b.ordered, CASE b.part_type WHEN 'C' THEN  b.ordered ELSE a.qty END, CASE b.part_type WHEN 'C' THEN 'Y' ELSE 'N' END
			FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	dbo.ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		a.order_type = 'S'	
			AND		a.qty > 0
			ORDER BY a.line_no
		END
		ELSE
		BEGIN
			INSERT	#allocation_lines (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, kit_item) -- v1.3
			SELECT	DISTINCT a.order_no, a.order_ext, @cons_no, a.line_no, CASE c.part_type WHEN 'C' THEN  c.part_no ELSE a.part_no END, a.bin_no, -- v1.3
					c.ordered, CASE c.part_type WHEN 'C' THEN c.ordered ELSE a.qty END, CASE c.part_type WHEN 'C' THEN 'Y' ELSE 'N' END
			FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	dbo.cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			JOIN	dbo.ord_list c (NOLOCK)
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			AND		a.line_no = c.line_no
			WHERE	b.consolidation_no = @cons_no
			AND		a.order_type = 'S'
			AND		a.qty > 0
			ORDER BY a.order_no, a.order_ext, a.line_no
		END

		SELECT	@order_qty = SUM(a.alloc_qty)
		FROM	#allocation_lines a 
		JOIN	dbo.inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.cons_no = @cons_no
		-- v1.4 AND		b.type_code IN ('SUN','FRAME','CASE')

	END
	ELSE
	BEGIN
		SELECT	@order_qty = SUM(a.qty)
		FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	dbo.inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.order_type = @order_type
		-- v1.4 AND		b.type_code IN ('SUN','FRAME','CASE')
	END

	IF (@order_qty IS NULL)
		RETURN	

	-- v1.2 Start
	SET @result_id = 0

	EXEC @result_id = dbo.cvo_get_pack_calc_sp @order_qty

	IF NOT EXISTS (SELECT 1 FROM #pack_results WHERE result_id = @result_id)
	BEGIN
		GOTO CLEANUP
	END
	-- v1.2 End

	-- Get allocation details
	IF (@cons_no = 0)
	BEGIN
		IF (@order_type = 'S')
		BEGIN
			INSERT	#allocations (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, packed_qty, kit_item) -- v1.3
			SELECT	DISTINCT a.order_no, a.order_ext, 0, a.line_no, CASE b.part_type WHEN 'C' THEN b.part_no ELSE a.part_no END, a.bin_no,  -- v1.3
					b.ordered, CASE b.part_type WHEN 'C' THEN b.ordered ELSE a.qty END, 0, CASE b.part_type WHEN 'C' THEN 'Y' ELSE 'N' END
			FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	dbo.ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		a.order_type = 'S'	
			AND		a.qty > 0
			ORDER BY a.line_no		

			IF EXISTS (SELECT 1 FROM #allocations (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND kit_item = 'Y')
			BEGIN
				INSERT	#allocations (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, packed_qty, kit_item)	 -- v1.3		
				SELECT	order_no, order_ext, 0, line_no, part_no, '', ordered, ordered, 0, 'N' -- v1.3
				FROM	ord_list (NOLOCK) 
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_type = 'C'
			END

		END
		ELSE
		BEGIN
			INSERT	#allocations (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, packed_qty) -- v1.3
			SELECT	a.order_no, a.order_ext, 0, a.line_no, a.part_no, a.bin_no, a.qty, a.qty, 0 -- v1.3
			FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	dbo.xfer_list b (NOLOCK)
			ON		a.order_no = b.xfer_no
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		a.order_type = 'T'	
			AND		a.qty > 0
			ORDER BY a.line_no		
		END
	END
	ELSE
	BEGIN
		INSERT	#allocations (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, packed_qty, kit_item) -- v1.3
		SELECT	DISTINCT a.order_no, a.order_ext, @cons_no, a.line_no, CASE c.part_type WHEN 'C' THEN c.part_no ELSE a.part_no END, a.bin_no,  -- v1.3
				c.ordered, CASE c.part_type WHEN 'C' THEN c.ordered ELSE a.qty END, 0, CASE c.part_type WHEN 'C' THEN 'Y' ELSE 'N' END
		FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	dbo.cvo_masterpack_consolidation_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		JOIN	dbo.ord_list c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	b.consolidation_no = @cons_no
		AND		a.order_type = 'S'
		AND		a.qty > 0
		ORDER BY a.order_no, a.order_ext, a.line_no

		IF EXISTS (SELECT 1 FROM #allocations (NOLOCK) WHERE cons_no = @cons_no AND kit_item = 'Y')
		BEGIN
			INSERT	#allocations (order_no, order_ext, cons_no, line_no, part_no, bin_no, ord_qty, alloc_qty, packed_qty, kit_item)	 -- v1.3		
			SELECT	a.order_no, a.order_ext, @cons_no, a.line_no, a.part_no, '', a.ordered, a.ordered, 0, 'N' -- v1.3
			FROM	ord_list a (NOLOCK)
			JOIN	dbo.cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext 
			WHERE	b.consolidation_no = @cons_no
			AND		a.part_type = 'C'
		END

	END

	IF NOT EXISTS ( SELECT 1 FROM #allocations)
		RETURN


	-- Process loop to fill boxes
	-- v1.2 Start
	SET @pack_row_id = 0
	SET @row_id = 0
	SET @remaining_qty = @order_qty
	SET @box_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @pack_row_id = row_id,
				@box_type = box,
				@box_capacity = qty
		FROM	#pack_results
		WHERE	row_id > @pack_row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		SET @box_remainder = @box_capacity
		SET @row_id = 0
		SET @box_id = @box_id + 1

		WHILE (@box_remainder > 0)
		BEGIN
			SELECT	TOP 1 @row_id = row_id,
					@alloc_order_no = order_no,
					@alloc_order_ext = order_ext,
					@line_no = line_no,
					@part_no = part_no,
					@ord_qty = ord_qty,
					@alloc_qty = alloc_qty - packed_qty,
					@kit_item = kit_item
			FROM	#allocations
			WHERE	row_id > @row_id
			AND		packed_qty < alloc_qty
			AND		alloc_qty > 0
			ORDER BY row_id ASC

			IF (@@ROWCOUNT = 0)
				BREAK					

			IF (@alloc_qty <= @box_remainder)
			BEGIN
				IF (@kit_item = 'Y')
				BEGIN
					DELETE	dbo.cvo_pre_packaging WHERE order_no = @alloc_order_no AND order_ext = @alloc_order_ext AND line_no = @line_no AND box_id = @box_id
				
					INSERT	dbo.cvo_pre_packaging (order_no, order_ext, cons_no, line_no, part_no, ordered, pack_qty, box_type, box_id, carton_no, order_type, kit_item)						
					SELECT	a.order_no, a.order_ext, @cons_no, a.line_no, a.part_no, a.qty, a.qty, @box_type, @box_id, 0, @order_type, CASE b.part_type WHEN 'C' THEN 'Y' ELSE 'N' END					
					FROM	dbo.tdc_soft_alloc_tbl a (NOLOCK)
					JOIN	dbo.ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @alloc_order_no
					AND		a.order_ext = @alloc_order_ext
					AND		a.line_no = @line_no	
				END
				ELSE
				BEGIN
					DELETE	dbo.cvo_pre_packaging WHERE order_no = @alloc_order_no AND order_ext = @alloc_order_ext AND line_no = @line_no AND box_id = @box_id
				
					INSERT	dbo.cvo_pre_packaging (order_no, order_ext, cons_no, line_no, part_no, ordered, pack_qty, box_type, box_id, carton_no, order_type, kit_item)						
					SELECT	@alloc_order_no, @alloc_order_ext, @cons_no, @line_no, @part_no, @ord_qty, @alloc_qty, @box_type, @box_id, 0, @order_type, 'N'					
				END

				UPDATE	#allocations
				SET		packed_qty = packed_qty + @alloc_qty
				WHERE	row_id = @row_id

				SET @packed_qty = @packed_qty + @alloc_qty
				SET @box_remainder = @box_remainder - @alloc_qty
			END
			ELSE
			BEGIN
				SET @alloc_qty = @box_remainder

				UPDATE	#allocations
				SET		packed_qty = packed_qty + @alloc_qty
				WHERE	row_id = @row_id

				SET @packed_qty = @packed_qty + @alloc_qty
				SET @box_remainder = @box_remainder - @alloc_qty

				DELETE	dbo.cvo_pre_packaging WHERE order_no = @alloc_order_no AND order_ext = @alloc_order_ext AND line_no = @line_no AND box_id = @box_id
				
				INSERT	dbo.cvo_pre_packaging (order_no, order_ext, cons_no, line_no, part_no, ordered, pack_qty, box_type, box_id, carton_no, order_type, kit_item)						
				SELECT	@alloc_order_no, @alloc_order_ext, @cons_no, @line_no, @part_no, @ord_qty, @alloc_qty, @box_type, @box_id, 0, @order_type, 'N'					

				BREAK
			END			
		END
	END

	-- CLEAN UP
	CLEANUP:

	DROP TABLE #allocations 
	DROP TABLE #allocation_lines
	DROP TABLE #pack_results -- v1.2

END
GO
GRANT EXECUTE ON  [dbo].[cvo_calculate_packaging_sp] TO [public]
GO
