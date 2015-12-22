SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_Held_Orders_sp] @for_print int = 0, @hold varchar(20) = null, @debug int = 0
AS
BEGIN

-- EXEC [cvo_release_Held_Orders_sp] 0, 'TRXE', 0
-- EXEC [cvo_release_Held_Orders_sp] 0, null , 1

-- For T&T Drop Orders to Wayne, and/or other holds
-- it will release any order with EITHER the hold_reason or prior hold matching the @hold parameter

	-- DIRECTIVES
	SET NOCOUNT ON

	--DECLARE @for_print int, @hold varchar(20)
	--SELECT @FOR_PRINT = 0, @HOLD = 'TRXE'

	if @hold is null return 0

	-- DECLARATIONS
	DECLARE @row_id			int,
			@last_row_id	int,
			@order_no		int,
			@order_ext		int,
			@rc				int

	-- WORKING TABLES
	CREATE TABLE #hold_orders (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		global_ship		varchar(10),
		prior_hold		varchar(20))

	CREATE TABLE #hold_print_orders (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		global_ship		varchar(10))

	-- If just printing then skip this section
	
	

	IF (@for_print = 0)
	BEGIN
		-- Insert working data
		INSERT	#hold_orders (order_no, order_ext, global_ship, prior_hold)
		SELECT	a.order_no, 
				a.ext,
				a.sold_to,
				ISNULL(b.prior_hold,'')
		FROM	orders_all a (NOLOCK)
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.ext
-- v1.2	LEFT JOIN tdc_soft_alloc_tbl c (NOLOCK)
-- v1.2	ON		a.order_no = c.order_no
-- v1.2	AND		a.ext = c.order_ext
-- v1.2	AND		c.order_type = 'S'
		WHERE	a.type = 'I'
		AND		a.status = 'A'
		AND		(a.hold_reason = @hold or isnull(b.prior_hold,'') = @hold)
-- v1.2	AND		c.order_no IS NULL
	
		if @debug = 1 select * from #hold_orders
		
		-- Step 1 - Update the hold reason where there is a prior hold
		UPDATE	a
		SET		hold_reason = b.prior_hold
		FROM	orders_all a
		JOIN	#hold_orders b
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		WHERE	b.prior_hold > ''

		-- Step 2 - Remove any records where there is a hold value
		--DELETE	#hold_orders
		--WHERE	prior_hold > ''

		-- Step 3 Run through each order, release the hold and allocate
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#hold_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		if @debug = 1 select @last_row_id

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			UPDATE	orders_all
			SET		status = 'N',
					printed = 'N',
					hold_reason = ''
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			-- v1.1 Start
			UPDATE	cvo_orders_all
			SET		GSH_released = 1
			WHERE	order_no = @order_no
			AND		ext = @order_ext
			and gsh_released <> 1
			-- v1.1 End			

			-- v1.3 Start
			-- Future Allocations
			IF NOT EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr a (NOLOCK)
					JOIN cvo_orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext
							WHERE	b.allocation_date <= getdate() AND a.status = -3)
			BEGIN
				
				if @debug = 1 select ' * future allocation *'

				DELETE	#hold_orders
				WHERE	row_id = @row_id

				SET @last_row_id = @row_id

				SELECT	TOP 1 @row_id = row_id,
						@order_no = order_no,
						@order_ext = order_ext
				FROM	#hold_orders
				WHERE	row_id > @last_row_id
				ORDER BY row_id ASC

				CONTINUE
			END

			---- v1.3 End

			EXEC @rc = tdc_order_after_save @order_no, @order_ext   
				
			if @debug = 1 select @rc

			-- Allocation was successful
			IF (@rc <> 0) 
			BEGIN
				DELETE	#hold_orders
				WHERE	row_id = @row_id
			END

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext
			FROM	#hold_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END

		-- Step 4 - Print Pick Tickets
		if @debug = 1 select '-- Step 4 - Print Pick Tickets'

		INSERT	#hold_print_orders (order_no, order_ext, global_ship)
		SELECT	order_no,
				order_ext,
				global_ship
		FROM	#hold_orders	
		ORDER BY global_ship, order_no, order_ext
		
		if @debug = 1 select * from #hold_print_orders

	END


	IF (@for_print = 1)
	BEGIN
		INSERT	#hold_print_orders (order_no, order_ext, global_ship)
		SELECT	order_no,
				order_ext,
				global_ship
		FROM	#global_ship_print	
		ORDER BY global_ship, order_no, order_ext
	END


	-- Step 5 Run through each order and print the pick tickets in global ship order
	if @debug = 1 select '-- Step 5 Run through each order and print the pick tickets in global ship order'

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#hold_print_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext --, 1 -- print to backorder printer

		INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , rtrim(@hold)+'_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:Q;' + 'HOLD_REASON:'+@HOLD
		FROM	orders_all a (NOLOCK)
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.ext
		WHERE	a.order_no = @order_no
		AND		a.ext = @order_ext
			

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#hold_print_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END
	
	-- select * From #hold_orders


END
GO
