SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Procedure CVO_Process_Held_Substitution_orders_sp    Script Date: 12/01/2010  ***** 
Object:      Procedure  CVO_Process_Held_Substitution_orders_sp  
Source file: CVO_Process_Held_Substitution_orders_sp.sql
Author:		 Craig Boston
Created:	 12/13/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.1 CB 01/27/2011	-	Add in processing for substitution orders where the frame is not available

When substituting temples on an order if no stock exists the order is placed on hold (orders.status = 'A'
and hold_reason = 'NA'). This routine should be set up as a scheduled task to run. It checks if the stock is now
available and if so releases the hold and allows the auto allocate to run.
Only if all parts are available does it release the order.

BEGIN TRAN
select order_no, ext, status, hold_reason, type from orders (NOLOCK) where order_no in (1377,1378)
select * from tdc_soft_alloc_tbl where order_no in (1377,1378)
select tx_lock, * from tdc_pick_queue order by tran_id desc 
EXEC CVO_Process_Held_Substitution_orders_sp
select order_no, ext, status, hold_reason from orders (NOLOCK) where order_no in (1377,1378)
select * from tdc_soft_alloc_tbl where order_no in (1377,1378)
select tx_lock, * from tdc_pick_queue order by tran_id desc
ROLLBACK TRAN
COMMIT TRAN


*/

CREATE PROC [dbo].[CVO_Process_Held_Substitution_orders_sp]
AS
BEGIN
	-- Declaration
	DECLARE	@ID			int,
			@last_ID	int,
			@order_no	int,
			@order_ext	int,
			@location	varchar(10),
			@line_no	int,
			@part_no	varchar(30),
			@ordered	decimal(20,8),
			@avail_stock decimal(20,8),
			@row_id		int,
			@last_row_id int,
			@original_part varchar(30),
			@qty		decimal(20,8)
	

	-- Working tables
	CREATE TABLE #wip (	id				int identity(1,1),	
						order_no		int,
						order_ext		int,
						location		varchar(10),
						line_no			int,
						part_no			varchar(30),
						ordered			decimal(20,8),
						has_stock		int)

	-- Table to hold in stock qty
	-- use this to reduce the available qty in this routine
	CREATE TABLE #stock (	id				int identity(1,1),
							location		varchar(10),
							part_no			varchar(30),
							in_stock		decimal(20,8))

	-- Orders to process
	CREATE TABLE #orders (	id				int identity(1,1),	
							order_no		int,
							order_ext		int)

	-- Populate the working table
	INSERT	#wip (order_no, order_ext, location, line_no, part_no, ordered, has_stock)
	SELECT	a.order_no, a.ext, b.location, b.line_no, c.part_no, b.ordered, 0
	FROM	orders a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	JOIN	cvo_ord_list_kit c (NOLOCK)
	ON		b.order_no = c.order_no
	AND		b.order_ext = c.order_ext
	AND		b.line_no = c.line_no
	WHERE	a.status = 'A'
	AND		a.hold_reason = 'NA'
	AND		c.replaced = 'S'
	ORDER BY a.order_no, a.ext, b.line_no

	-- v1.1 Insert lines with frames on
	INSERT	#wip (order_no, order_ext, location, line_no, part_no, ordered, has_stock)
	SELECT	DISTINCT a.order_no, a.ext, b.location, b.line_no, b.part_no, b.ordered, 0
	FROM	orders a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	JOIN	cvo_ord_list_kit c (NOLOCK)
	ON		b.order_no = c.order_no
	AND		b.order_ext = c.order_ext
	JOIN	inv_master d (NOLOCK)
	ON		b.part_no = d.part_no
	WHERE	a.status = 'A'
	AND		a.hold_reason = 'NA'
	AND		c.replaced = 'S'
	AND		d.type_code in ('FRAME','SUN')
	ORDER BY a.order_no, a.ext, b.line_no

	-- Group by parts and updated the available
	INSERT	#stock (location, part_no, in_stock)
	SELECT	location, part_no, 0
	FROM	#wip
	GROUP BY location, part_no

	-- Step through each part required and retrive the stock figure
	SET @last_ID = 0

	SELECT	TOP 1 @ID = id,
			@location = location,
			@part_no = part_no
	FROM	#stock
	WHERE	id > @last_ID
	ORDER BY id

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Check if stock is available
		EXEC @avail_stock = dbo.CVO_CheckAvailabilityInStock_sp @part_no, @location

		-- Update #stock table
		UPDATE	#stock
		SET		in_stock = @avail_stock
		WHERE	location = @location
		AND		part_no = @part_no
		
		SET @last_ID = @ID

		SELECT	TOP 1 @ID = id,
				@location = location,
				@part_no = part_no
		FROM	#stock
		WHERE	id > @last_ID
		ORDER BY id

	END

	-- Update the #wip table where no stock is available
	UPDATE	#wip
	SET		has_stock = -1
	FROM	#wip a
	JOIN	#stock b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		b.in_stock = 0

	-- If any orders can't be fulfilled then remove from the #wip table
	UPDATE	a
	SET		has_stock = -1
	FROM	#wip a
	JOIN	#wip b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.has_stock = -1

	DELETE	#wip
	WHERE	has_stock = -1


	-- Step through each order line and check if the stock is now available
	SET @last_ID = 0

	SELECT	TOP 1 @ID = id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location,
			@line_no = line_no,
			@part_no = @part_no,
			@ordered = ordered
	FROM	#wip
	WHERE	id > @last_ID
	ORDER BY id

	WHILE @@ROWCOUNT <> 0
	BEGIN

		SET @avail_stock = 0

		SELECT	@avail_stock = in_stock
		FROM	#stock
		WHERE	location = @location
		AND		part_no = @part_no

		IF @avail_stock >= @ordered
		BEGIN
		
			UPDATE	#wip
			SET		has_stock = 1
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no

			UPDATE	#stock
			SET		in_stock = in_stock - @ordered
			WHERE	location = @location
			AND		part_no = @part_no
		END	

		SET @last_ID = @ID

		SELECT	TOP 1 @ID = id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location,
				@line_no = line_no,
				@part_no = @part_no,
				@ordered = ordered
		FROM	#wip
		WHERE	id > @last_ID
		ORDER BY id
	
	END

	-- If any orders can't be fulfilled then remove from the #wip table
	UPDATE	a
	SET		has_stock = -1
	FROM	#wip a
	JOIN	#wip b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.has_stock = -1

	DELETE	#wip
	WHERE	has_stock = -1

	-- Update the orders that can be fulfilled
	INSERT	#orders (order_no, order_ext)
	SELECT	order_no, order_ext
	FROM	#wip
	GROUP BY order_no, order_ext


	UPDATE	orders_all
	SET		status = 'N',
			hold_reason = ''
	FROM	orders_all a
	JOIN	#orders	b		
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext


	-- Step through each order line and call the warehouse routine
	SET @last_ID = 0

	SELECT	TOP 1 @ID = id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#orders
	WHERE	id > @last_ID
	ORDER BY id

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- This is called twice, the first time for the substitutions and then for the rest of the order
		EXEC dbo.tdc_order_after_save @order_no, @order_ext
		EXEC dbo.tdc_order_after_save @order_no, @order_ext	

		-- Step through each order line kit items and create the MGTB2B moves
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@line_no = line_no,
				@location = location,
				@part_no = part_no,
				@original_part = part_no_original
		FROM	dbo.cvo_ord_list_kit (NOLOCK)
		WHERE	row_id > @last_row_id
		AND		order_no = @order_no
		AND		order_ext = @order_ext
		AND		replaced = 'S'
		ORDER BY row_id

		WHILE @@ROWCOUNT <> 0
		BEGIN

			SELECT	@qty = ordered
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no

			EXEC CVO_Create_Substitution_MGMB2B_Moves_sp @order_no,@order_ext,@line_no,@location,@part_no,@original_part,@original_part,@qty

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@line_no = line_no,
					@location = location,
					@part_no = part_no,
					@original_part = part_no_original
			FROM	dbo.cvo_ord_list_kit (NOLOCK)
			WHERE	row_id > @last_row_id
			AND		order_no = @order_no
			AND		order_ext = @order_ext
			AND		replaced = 'S'
			ORDER BY row_id

		END
		
		SET @last_ID = @ID

		SELECT	TOP 1 @ID = id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#orders
		WHERE	id > @last_ID
		ORDER BY id
	
	END
	
	DROP TABLE #wip
	DROP TABLE #stock
	DROP TABLE #orders


END
GO
GRANT EXECUTE ON  [dbo].[CVO_Process_Held_Substitution_orders_sp] TO [public]
GO
