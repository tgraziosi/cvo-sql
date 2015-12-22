SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
BEGIN TRAN
EXEC cvo_create_soft_alloc_from_old_sp 1419032, 0
select * from cvo_soft_alloc_hdr where order_no = 1419032
select * from cvo_soft_alloc_det where order_no = 1419032
select * from tdc_soft_alloc_tbl where order_no = 1419032
ROLLBACK TRAN
COMMIT TRAN
*/
CREATE PROC [dbo].[cvo_create_soft_alloc_from_old_sp]	@order_no		int, 
													@order_ext		int
AS 
BEGIN
	-- Declarations
	DECLARE @soft_alloc_no	int,
			@alloc_qty		decimal(20,8),
			@sa_qty			decimal(20,8),
			@row_id			int,
			@last_row_id	int,
			@location		varchar(10),
			@part_no		varchar(30),
			@qty			decimal(20,8),
			@avail_qty		decimal(20,8),
			@inv_avail		smallint

	-- Create working table
	CREATE TABLE #tmp_alloc (
			line_no		int,
			qty			decimal(20,8))

	-- Get the quantity if any that are allocated
	SELECT	@alloc_qty = SUM(qty) 
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext

	IF (@alloc_qty IS NULL)
		SET @alloc_qty = 0

	-- insert the allocated items
	INSERT	#tmp_alloc
	SELECT	line_no, SUM(qty)
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	GROUP BY line_no

	-- Get the total qauntity from the order
	SELECT	@sa_qty = SUM(ordered)
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext

	-- Get the next soft alloc number
	BEGIN TRAN
	UPDATE	dbo.cvo_soft_alloc_next_no
	SET		next_no = next_no + 1	
	
	SELECT	@soft_alloc_no = next_no
	FROM	dbo.cvo_soft_alloc_next_no
	COMMIT TRAN
	
	
	IF	(@sa_qty = @alloc_qty) -- Order Fully allocated
	BEGIN

		-- Create the soft alloc header with a status of processed
		INSERT	dbo.cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		SELECT	@soft_alloc_no, @order_no, @order_ext, location, 0, -2
		FROM	dbo.orders_all (NOLOCK)	
		WHERE	order_no = @order_no
		AND		ext = @order_ext	

		-- Create the soft alloc detail with a status of processed
		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)	-- 10.5		
		SELECT	@soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, a.ordered,
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, -2, b.add_case -- v10.5
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext

		-- Create the soft alloc detail for custom frames with a status of processed
		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, a.ordered,
				1, 0, 0, 0, 0, 0, -2
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		b.replaced = 'S'

		DELETE	cvo_soft_alloc_start
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext	

	END
	ELSE
	BEGIN -- either not allocated or partially allocated

		INSERT	dbo.cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		SELECT	@soft_alloc_no, @order_no, @order_ext, location, 0, 0
		FROM	dbo.orders_all (NOLOCK)	
		WHERE	order_no = @order_no
		AND		ext = @order_ext	

		-- Create the soft alloc_detail
		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)	-- 10.5		
		SELECT	@soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, (a.ordered - ISNULL(c.qty,0)),
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case -- v10.5
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		LEFT JOIN
				#tmp_alloc c (NOLOCK)
		ON		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		(a.ordered - ISNULL(c.qty,0)) > 0

		-- v10.6
-- v1.2		EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @order_no, @order_ext

		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, (a.ordered - ISNULL(c.qty,0)),
				1, 0, 0, 0, 0, 0, 0
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		LEFT JOIN
				#tmp_alloc c (NOLOCK)
		ON		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		b.replaced = 'S'	
		AND		(a.ordered - ISNULL(c.qty,0)) > 0	

		-- Set the inv available flag
		CREATE TABLE #soft_alloc_qty (qty	decimal(20,8))
		SET @last_row_id = 0 

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@part_no = part_no,
				@qty = quantity
		FROM	cvo_soft_alloc_det (NOLOCK)
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			SET @sa_qty = 0

			EXEC @avail_qty = CVO_CheckAvailabilityInStock_sp  @part_no, @location

			INSERT #soft_alloc_qty
			EXEC dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @part_no

			SELECT @sa_qty = qty FROM #soft_alloc_qty

			DELETE #soft_alloc_qty

			IF (@qty <= (@avail_qty - @sa_qty )) -- v1.8
				SET @inv_avail = 1
			ELSE
				SET @inv_avail = NULL
			-- v1.1 End

			UPDATE	dbo.cvo_soft_alloc_det
			SET		inv_avail = @inv_avail
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id 

			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@part_no = part_no,
					@qty = quantity
			FROM	cvo_soft_alloc_det (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		row_id > @last_row_id
			ORDER BY row_id ASC
		END

		DELETE	cvo_soft_alloc_start
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

	END

	-- v1.2 Start
	UPDATE	a
	SET		a.add_case = 'Y'
	FROM	cvo_ord_list a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_case = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	UPDATE	b
	SET		b.from_line_no = 0
	FROM	cvo_ord_list a (NOLOCK)
	JOIN	cvo_ord_list b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.from_line_no
	WHERE	b.from_line_no <> 0
	AND		b.is_case = 1
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext

	UPDATE	a
	SET		add_case_flag = b.add_case
	FROM	cvo_soft_alloc_det a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	-- v1.2 End

END
GO
GRANT EXECUTE ON  [dbo].[cvo_create_soft_alloc_from_old_sp] TO [public]
GO
