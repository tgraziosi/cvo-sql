SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_CF_OOS_check_sp]	@order_no   int,  
												@order_ext  int,
												@line_no	int   
AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	
	-- Declarations
	DECLARE	@soft_alloc_no		int,
			@id					int,
			@last_id			int,
			@location			varchar(10),
			@part_no			varchar(30),
			@in_stock			decimal(20,8),
			@alloc_qty			decimal(20,8),
			@quar_qty			decimal(20,8),
			@sa_qty				decimal(20,8),
			@qty				decimal(20,8), -- v1.1
			@hard_alloc_qty		decimal(20,8), -- v1.4
			@check_stock		SMALLINT -- v1.4

	-- Create Working Table
	CREATE TABLE #cf_break (id				int identity(1,1),
							location		varchar(10),
							line_no			int,
							part_no			varchar(30),
							qty				decimal(20,8),
							no_stock		int)

	CREATE TABLE #cf_break_kit 
						   (id				int identity(1,1),
							location		varchar(10),
							qty				decimal(20,8), -- v1.1
							kit_line_no		int,
							kit_part_no		varchar(30),
							no_stock		int)

	CREATE TABLE #wms_ret ( location		varchar(10),
							part_no			varchar(30),
							allocated_qty	decimal(20,8),
							quarantined_qty	decimal(20,8),
							apptype			varchar(20))

	CREATE TABLE #cf_allocs (order_no		int,
							order_ext		int,
							line_no			int,
							no_stock		int)	

	SELECT @soft_alloc_no = MAX(soft_alloc_no) FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext

	-- Run through the soft allocations where there are custom frames
	INSERT	#cf_allocs (order_no, order_ext, line_no, no_stock)
	SELECT	@order_no,
			@order_ext,
			@line_no,
			0

	DELETE	#cf_break
	DELETE	#cf_break_kit

	-- Get a list of the custom frame breaks from the order
	INSERT	#cf_break (location, line_no, part_no, qty, no_stock)
	SELECT	DISTINCT a.location,
			a.line_no,
			a.part_no,
			a.ordered,
			0
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list_kit b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.line_no = @line_no
	AND		b.replaced = 'S'

	INSERT	#cf_break_kit (location, qty, kit_line_no, kit_part_no, no_stock) -- v1.1 add qty
	SELECT	b.location,
			b.ordered, 
			a.line_no,
			a.part_no,
			0
	FROM	cvo_ord_list_kit a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.line_no = @line_no
	AND		a.replaced = 'S'

	IF EXISTS (SELECT 1 FROM #cf_break) -- Test for substitution at frame level
	BEGIN
		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@location = location,
				@line_no = line_no,
				@part_no = part_no,
				@qty = qty -- v1.1
		FROM	#cf_break
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- START v1.4 
			-- Check if the frame is hard allocated
			SET @check_stock = 1 -- True
			SET @hard_alloc_qty = 0
			SELECT 
				@hard_alloc_qty = SUM(qty)
			FROM
				dbo.tdc_soft_alloc_tbl (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @order_ext
				AND line_no = @line_no
				AND location = @location
				AND part_no = @part_no
				AND order_type = 'S'

			-- If qty ordered <= qty hard allocated then we don't need to process this line
			IF @qty <= ISNULL(@hard_alloc_qty,0)
			BEGIN
				SET @check_stock = 0 -- False

				-- Remove the kit lines for this order
				DELETE FROM #cf_break_kit WHERE kit_line_no = @line_no
			END

			-- If qty ordered > qty hard allocated then update the amount we need to check for
			IF (@qty > ISNULL(@hard_alloc_qty,0)) AND (ISNULL(@hard_alloc_qty,0) <> 0)
			BEGIN
				SET @qty = @qty - @hard_alloc_qty

				-- Update teables with new qty
				UPDATE
					#cf_break
				SET
					qty = @qty
				WHERE
					id = @id

				UPDATE
					#cf_break_kit
				SET
					qty = @qty
				WHERE
					kit_line_no = @line_no
			END

			IF @check_stock = 1
			BEGIN
			-- END v1.4


				-- v1.3 Start
				SET @in_stock = 0
				SET @alloc_qty = 0
				SET @quar_qty = 0
				SET @sa_qty = 0
				-- v1.3 End

				-- Inventory - in stock
				-- START v1.2
				SELECT	@in_stock = in_stock - ISNULL(replen_qty,0)
				--SELECT	@in_stock = in_stock
				-- END v1.2
				FROM	cvo_inventory2 (NOLOCK) -- v1.3
				WHERE	location = @location
				AND		part_no = @part_no

				-- WMS - allocated and quarantined
				DELETE	#wms_ret

				INSERT	#wms_ret
				EXEC tdc_get_alloc_qntd_sp @location, @part_no

				SELECT	@alloc_qty = allocated_qty,
						@quar_qty = quarantined_qty
				FROM	#wms_ret

				IF (@alloc_qty IS NULL)
					SET @alloc_qty = 0

				IF (@quar_qty IS NULL)
					SET @quar_qty = 0

				SELECT	@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)
				FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
				WHERE	a.status IN (0, 1, -1, -4) -- v1.1 Include -4
-- v1.1			AND		a.soft_alloc_no  <> @soft_alloc_no
				AND		a.soft_alloc_no  < @soft_alloc_no -- v1.1
				AND		a.location = @location
				AND		a.part_no = @part_no
				-- v1.2 End

				IF (@sa_qty IS NULL)
					SET @sa_qty = 0

				-- Compare - if no stock available then mark the record
				IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) -- <= 0) v1.1 Check against order quantity
				BEGIN
					UPDATE	#cf_break
					SET		no_stock = 1
					WHERE	id = @id

				END
			END -- v1.4
			
			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@location = location,
					@line_no = line_no,
					@part_no = part_no,
					@qty = qty -- v1.1
			FROM	#cf_break
			WHERE	id > @last_id
			ORDER BY id ASC

		END
	END
	
	IF EXISTS (SELECT 1 FROM #cf_break_kit) -- Test for substitution at kit level
	BEGIN
		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@location = location,
				@qty = qty, -- v1.1
				@line_no = kit_line_no,
				@part_no = kit_part_no
		FROM	#cf_break_kit
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- v1.3 Start
			SET @in_stock = 0
			SET @alloc_qty = 0
			SET @quar_qty = 0
			SET @sa_qty = 0
			-- v1.3 End

			-- Inventory - in stock
			-- START v1.2
			SELECT	@in_stock = in_stock - ISNULL(replen_qty,0)
			--SELECT	@in_stock = in_stock
			-- END v1.2
			FROM	cvo_inventory2 (NOLOCK) -- v1.3
			WHERE	location = @location
			AND		part_no = @part_no

			-- WMS - allocated and quarantined
			DELETE	#wms_ret
	
			INSERT	#wms_ret
			EXEC tdc_get_alloc_qntd_sp @location, @part_no

			SELECT	@alloc_qty = allocated_qty,
					@quar_qty = quarantined_qty
			FROM	#wms_ret

			IF (@alloc_qty IS NULL)
				SET @alloc_qty = 0

			IF (@quar_qty IS NULL)
				SET @quar_qty = 0

			SELECT	@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
			WHERE	a.status IN (0, 1, -1, -4) -- v1.1 include -4
-- v1.1		AND		a.soft_alloc_no  <> @soft_alloc_no
			AND		a.soft_alloc_no  < @soft_alloc_no -- v1.1
			AND		a.location = @location
			AND		a.part_no = @part_no
			-- v1.2 End


			IF (@sa_qty IS NULL)
				SET @sa_qty = 0

			-- Compare - if no stock available then mark the record
			IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) --<= 0) v1.1 Check against order qty
			BEGIN
				UPDATE	#cf_break_kit
				SET		no_stock = 1
				WHERE	id = @id

			END

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@location = location,
					@qty = qty, -- v1.1
					@line_no = kit_line_no,
					@part_no = kit_part_no
			FROM	#cf_break_kit
			WHERE	id > @last_id
			ORDER BY id ASC

		END
	END

	-- Mark the frame record if no stock available for the substitution
	UPDATE	a
	SET		no_stock = 1
	FROM	#cf_break a
	JOIN	#cf_break_kit b
	ON		a.line_no = b.kit_line_no
	WHERE	b.no_stock = 1

	-- Mark the data to be returned to show no stock is available
	UPDATE	a
	SET		no_stock = 1
	FROM	#cf_allocs a
	JOIN	#cf_break b
	ON		a.line_no = b.line_no
	WHERE	b.no_stock = 1

	IF EXISTS (SELECT 1 FROM #cf_allocs WHERE no_stock = 1)
		RETURN 1
	ELSE
		RETURN 0

	DROP TABLE #cf_allocs
	DROP TABLE #cf_break
	DROP TABLE #cf_break_kit
	DROP TABLE #wms_ret

END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_CF_OOS_check_sp] TO [public]
GO
