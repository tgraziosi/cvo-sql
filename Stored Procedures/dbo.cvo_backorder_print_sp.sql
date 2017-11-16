SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 26/10/2017 - Capture allocated backorders for printing

CREATE PROC [dbo].[cvo_backorder_print_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id			int,
			@order_no		int,
			@order_ext		int,
			@ordered		decimal(20,8),
			@allocated		decimal(20,8),
			@msg			varchar(1000),
			@count			int

	-- WORKING TABLES
	CREATE TABLE #orders_to_print (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		ship_complete	int,
		ok_to_print		int)

	CREATE TABLE #cons_orders_to_print (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		ship_complete	int,
		cons_no			int,
		ok_to_print		int)	

	-- PROCESSING
	SET @msg = 'Starting cvo_backorder_print_sp process'
	EXEC dbo.cvo_backorder_processing_log_sp @msg


	INSERT	#orders_to_print (order_no, order_ext, ship_complete, ok_to_print)
	SELECT	DISTINCT a.order_no,
			a.ext,
			a.back_ord_flag,
			1
	FROM	orders_all a (NOLOCK)
	JOIN	tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	a.status = 'N'
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		ISNULL(a.so_priority_code,'') <> '3'

	-- Remove any consolidated orders
	DELETE	a
	FROM	#orders_to_print a
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	-- Check for ship complete to make sure they are fully allocated
	SET	@row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#orders_to_print
		WHERE	row_id > @row_id
		AND		ship_complete = 1
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0 )
			BREAK

		SET @ordered = 0
		SET @allocated = 0

		SELECT	@ordered = SUM(ordered - shipped)
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		SELECT	@allocated = SUM(qty)
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		order_type = 'S'

		IF (@ordered <> @allocated)
		BEGIN
			UPDATE	#orders_to_print
			SET		ok_to_print = 0
			WHERE	row_id = @row_id
		END
	END

	INSERT	#cons_orders_to_print (order_no, order_ext, ship_complete, cons_no, ok_to_print)
	SELECT	DISTINCT a.order_no,
			a.ext,
			a.back_ord_flag,
			c.consolidation_no,
			1
	FROM	orders_all a (NOLOCK)
	JOIN	tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	JOIN	cvo_masterpack_consolidation_det c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext 
	WHERE	a.status = 'N'
	AND		a.ext > 0
	AND		a.who_entered = 'BACKORDR'
	AND		ISNULL(a.so_priority_code,'') <> '3'

	-- Check for ship complete to make sure they are fully allocated
	SET	@row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#cons_orders_to_print
		WHERE	row_id > @row_id
		AND		ship_complete = 1
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0 )
			BREAK

		SET @ordered = 0
		SET @allocated = 0

		SELECT	@ordered = SUM(ordered - shipped)
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		SELECT	@allocated = SUM(qty)
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		order_type = 'S'

		IF (@ordered <> @allocated)
		BEGIN
			UPDATE	#cons_orders_to_print
			SET		ok_to_print = 0
			WHERE	row_id = @row_id
		END
	END	

	-- Check that the whole consolidation is going to print
	CREATE TABLE #cons_checks (
		cons_no		int)

	INSERT	#cons_checks (cons_no)
	SELECT	DISTINCT cons_no
	FROM	#cons_orders_to_print
	WHERE	ok_to_print = 0

	DELETE	a
	FROM	#cons_orders_to_print a
	JOIN	#cons_checks b
	ON		a.cons_no = b.cons_no

	DROP TABLE #cons_checks

	DELETE	#orders_to_print
	WHERE	ok_to_print = 0

	DELETE	#cons_orders_to_print
	WHERE	ok_to_print = 0

	SET @count = 0
	SELECT	@count = COUNT(1)
	FROM	#orders_to_print

	SET @msg = 'cvo_backorder_print_sp process - ' + CAST(@count as varchar(20)) + ' orders selected for printing'
	EXEC dbo.cvo_backorder_processing_log_sp @msg

	-- Now print the non consolidated orders
	SET	@row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#orders_to_print
		WHERE	row_id > @row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0 )
			BREAK
	
		SET @msg = 'cvo_backorder_print_sp process - Printing Pick Ticket for order ' + CAST(@order_no AS varchar(10)) + '-' + CAST(@order_ext AS varchar(5))
		EXEC dbo.cvo_backorder_processing_log_sp @msg

		EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext,1	

		IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'Q')
		BEGIN
			DELETE	CVO_backorder_processing_pick_tickets
			WHERE	order_no = @order_no
			AND		ext = @order_ext
			AND		is_transfer = 0
			AND		printed = 0
		END

	END

	SET @count = 0
	SELECT	@count = COUNT(1)
	FROM	#cons_orders_to_print

	SET @msg = 'cvo_backorder_print_sp process - ' + CAST(@count as varchar(20)) + ' consolidated orders selected for printing'
	EXEC dbo.cvo_backorder_processing_log_sp @msg

	-- Now print the consolidated orders
	SET	@row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = cons_no
		FROM	#cons_orders_to_print
		WHERE	row_id > @row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0 )
			BREAK
	
		SET @msg = 'cvo_backorder_print_sp process - Printing Consolidated Pick Ticket for set ' + CAST(@row_id AS varchar(10)) 
		EXEC dbo.cvo_backorder_processing_log_sp @msg
					
		EXEC dbo.cvo_print_consolidated_pick_ticket_sp @row_id,1

		IF EXISTS (SELECT 1 FROM orders_all a (NOLOCK) JOIN cvo_masterpack_consolidation_det b (NOLOCK) ON a.order_no = b.order_no AND a.ext = b.order_ext
					WHERE a.status = 'Q' AND b.consolidation_no = @row_id)
		BEGIN
			DELETE	a
			FROM	CVO_backorder_processing_pick_tickets a
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK) 
			ON		a.order_no = b.order_no 
			AND		a.ext = b.order_ext
			WHERE	b.consolidation_no = @row_id
			AND		a.is_transfer = 0
			AND		a.printed = 0
		END
	END

	SET @msg = 'Completed cvo_backorder_print_sp process'
	EXEC dbo.cvo_backorder_processing_log_sp @msg

	-- CLEAN UP
	DROP TABLE #orders_to_print
	DROP TABLE #cons_orders_to_print

END
GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_print_sp] TO [public]
GO
