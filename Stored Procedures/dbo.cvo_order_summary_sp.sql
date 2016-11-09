SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 19/04/2012
-- v1.1 CT 07/08/2012 - Changed logic to correctly report for parts which are partly available after hard allocation.
-- v1.2 CT 13/09/2012 - Corrected logic used in v1.1	
-- v1.3 CB 05/10/2012 - Fix issue of the replen qty being counted twice
-- v1.4 CB 26/10/2012 - Need to include what has been already picked if being called onload otherwise it reports unavailable stock
-- v1.5 CT 26/10/2012 - Calculate and return order fill rate
-- v1.6 CT 04/12/2012 - Fill rate is only for frames and suns
-- v1.7 CB 14/12/2012 - Fix issue where reporting incorrectly for unavailable when hard allocated
-- v1.8 CB 20/12/2012 - Fix issue of showing unavailable after being soft allocated with inv available
-- v1.9 CB 24/12/2012 - Do no show unavailable or fill factor when void
-- v2.0 CB 04/01/2013 - Issue #1050 - Do not return fill rate if no frames or suns are on the order
-- v2.1 CT 16/01/2013 - Remove replenishment qty from availble figure
-- v2.2 CB 25/01/2013 - Fix issue when muliple lines exist for the same part - add line_no
-- v2.3 CT 11/02/2013 - Check what has already been picked whether onload is 0 or 1
-- v2.4	CT 14/02/2013 - When calculating qty picked or allocated, use line number in query
-- v2.5 CB 14/03/2013 - When the same part is added to an order more than once then need to decrement the available based on the current order
-- v2.6 CT 19/03/2013 - For onload = 1, if available qty is less than the qty allocated for the order, set available = qty allocated for the order
-- v2.7 CT 25/04/2013 - return list of unavailable parts
-- v2.8 CB 12/07/2013 - Issue #1341 - Not calculating the soft alloc qty correctly
-- v2.9 CB 14/03/2014 - Issue #1456 - Pass in optional part number for availability check
-- v3.0 CB 16/06/2014 - Performance
-- v3.1 CB 20/03/2015 - Performance Changes  
-- v3.2 CB 24/08/2016 - CVO-CF-49 - Dynamic Custom Frames  

-- Implement Soft Allocation
-- CVO-CF-3
/* TESTING
EXEC dbo.cvo_order_summary_sp 11868,1420240,0,1,'TESTPART10'
*/



CREATE PROC [dbo].[cvo_order_summary_sp]	@soft_alloc_no	int,
										@order_no		int,
										@order_ext		int,
										@onload			smallint,
										@part_no_in		varchar(30) = NULL -- v2.9
AS
BEGIN
	-- Declarations
	DECLARE	@row_id					int,
			@last_row_id			int,
			@location				varchar(10),
			@part_no				varchar(30),
			@instock				decimal(20,8),
			@allocated				decimal(20,8),
			@quarantine				decimal(20,8),
			@available				decimal(20,8),
			@soft_alloc_qty			decimal(20,8),
			@alloc_to_this_order	DECIMAL(20,8),	-- v1.1
			@qty_picked				decimal(20,8),  -- v1.4
			@fill_rate				DECIMAL(20,8),	-- v1.5
			@is_void				int,			-- v1.9
			@replen_qty				decimal(20,8),	-- v2.1
			@line_no				INT,				-- v2.4
			@ord_soft_alloc_qty		decimal(20,8), -- v2.5
			@unavailable_parts		VARCHAR(1000), -- v2.7
			@part_type				varchar(10) -- v3.2

	-- Working table
	DECLARE @returndata TABLE
	(
		row_id			int identity(1,1),
		type_code		varchar(20),
		location		varchar(10),
		part_no			varchar(30),
		avail_quantity	decimal(20,8),
		quantity		decimal(20,8),
		line_no			int -- v2.2
	)

	DECLARE @tdc_data TABLE
	(
		location		varchar(10),
		part_no			varchar(30),
		allocated_amt	decimal(20,8),
		quarantined_amt	decimal(20,8),
		apptype			varchar(20)
	)

	-- v2.9 Start - Moved
	DECLARE @temp TABLE (
			line_no		int,
			part_no		varchar(30),
			sa_qty		decimal(20,8),
			alloc_qty	decimal(20,8),
			changed		int)

	DECLARE @temp_sum TABLE (
			line_no		int,
			part_no		varchar(30),
			qty		decimal(20,8))
	-- v2.9 End

	SET @is_void = 0 -- v1.9

	SET @unavailable_parts = '' -- v2.7  

	-- v2.9 Start
	IF (@part_no_in IS NULL)
	BEGIN
		-- Depending on the onload flag either the data comes from soft allocation or the orders detail
		IF (@onload = 1)
		BEGIN
			INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
			SELECT	b.type_code, a.location, a.part_no, 0, sum(a.ordered), a.line_no -- v2.2
			FROM 	ord_list a (NOLOCK) 
			JOIN	inv_master b (NOLOCK) 
			ON		a.part_no = b.part_no 
			WHERE 	a.order_no = @order_no 
			AND		a.order_ext = @order_ext  
			GROUP BY b.type_code, a.location, a.part_no, a.line_no
			
			-- v1.9 Start
			SELECT	@is_void = 1
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext
			AND		void = 'V'
			-- v1.9 End
		END
		ELSE
		BEGIN
	--(a.quantity * -1)

			-- Create working table
	-- v2.9 Start
	--		DECLARE @temp TABLE (
	--				line_no		int,
	--				part_no		varchar(30),
	--				sa_qty		decimal(20,8),
	--				alloc_qty	decimal(20,8),
	--				changed		int)
	--
	--		DECLARE @temp_sum TABLE (
	--				line_no		int,
	--				part_no		varchar(30),
	--				qty		decimal(20,8))
	-- v2.9 End

			IF (@order_no > 0) -- v3.0 Start
			BEGIN
				INSERT	@temp
				SELECT	a.line_no, a.part_no, 0, a.qty, 0
				FROM	tdc_soft_alloc_tbl a (NOLOCK)
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext
			END -- v3.0 End

			-- Get soft allocation quantities
			INSERT	@temp
			SELECT	a.line_no, a.part_no, CASE WHEN a.deleted = 1 THEN a.quantity * -1 ELSE a.quantity END, 0, change
			FROM	cvo_soft_alloc_det a (NOLOCK)
			WHERE	a.soft_alloc_no = @soft_alloc_no

			-- If the allocated line has been changed then use the soft alloc quantity
			UPDATE	@temp
			SET		alloc_qty = 0
			WHERE	line_no IN (SELECT line_no FROM @temp WHERE changed <> 0)

			UPDATE	@temp
			SET		sa_qty = 0
			WHERE	line_no IN (SELECT line_no FROM @temp WHERE sa_qty < 0)

			INSERT  @temp_sum
			SELECT	line_no, part_no, SUM(sa_qty + alloc_qty)
			FROM	@temp
			GROUP BY line_no, part_no

			INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
			SELECT 	b.type_code, a.location, a.part_no, 0, sum(CASE WHEN a.deleted = 1 THEN 0 ELSE a.quantity END), a.line_no -- v2.2 
			FROM 	dbo.cvo_soft_alloc_det a (NOLOCK) 
			JOIN 	inv_master b (NOLOCK) 
			ON 		a.part_no = b.part_no 
			WHERE 	a.order_no = @order_no 
			AND 	a.order_ext = @order_ext 
			AND		a.soft_alloc_no = @soft_alloc_no
			AND		a.status NOT IN (-1, -2, -3)
			AND		a.kit_part = 0
			GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2

			INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
			SELECT 	b.type_code, a.location, a.part_no, 0, sum(CASE WHEN a.deleted = 1 THEN 0 ELSE a.quantity END), a.line_no -- v2.2
			FROM 	dbo.cvo_soft_alloc_det a (NOLOCK) 
			JOIN 	inv_master b (NOLOCK) 
			ON 		a.part_no = b.part_no 
			LEFT JOIN @returndata c -- v2.2
			ON		a.location = c.location -- v2.2 
			AND		a.part_no = c.part_no -- v2.2
			AND		a.line_no = c.line_no -- v2.2
			WHERE 	a.order_no = @order_no 
			AND 	a.order_ext = @order_ext 
			AND		a.soft_alloc_no = @soft_alloc_no
			AND		a.status IN (-1)
			AND		a.kit_part = 0
	-- v2.2		AND		a.part_no NOT IN (SELECT part_no FROM @returndata)
			GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2

			IF (@order_no > 0) -- v3.0 Start
			BEGIN
				INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
				SELECT	b.type_code, a.location, a.part_no, 0, sum(a.qty), a.line_no -- v2.2
				FROM 	tdc_soft_alloc_tbl a (NOLOCK) 
				JOIN	inv_master b (NOLOCK) 
				ON		a.part_no = b.part_no 
				LEFT JOIN @returndata c 
				ON		a.location = c.location
				AND		a.part_no = c.part_no
				AND		a.line_no = c.line_no -- v2.2
				WHERE 	a.order_no = @order_no 
				AND		a.order_ext = @order_ext 
				AND		c.part_no IS NULL
				AND		a.order_type = 'S'
				AND		a.order_no <> 0
				GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2

				INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
				SELECT	b.type_code, a.location, a.part_no, 0, sum(a.ordered), a.line_no -- v2.2
				FROM 	ord_list a (NOLOCK) 
				JOIN	inv_master b (NOLOCK) 
				ON		a.part_no = b.part_no 
				LEFT JOIN @returndata c 
				ON		a.location = c.location
				AND		a.part_no = c.part_no
				AND		a.line_no = c.line_no -- v2.2
				WHERE 	a.order_no = @order_no 
				AND		a.order_ext = @order_ext 
				AND		c.part_no IS NULL
				GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2
			END -- v3.0 End

			UPDATE	a
			SET		quantity = b.qty
			FROM	@returndata a
			JOIN	@temp_sum b
			ON		a.line_no = b.line_no
			AND		a.part_no = b.part_no
			

		END
	END
	ELSE
	BEGIN
		IF (@onload = 1)
		BEGIN
			INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
			SELECT	b.type_code, a.location, a.part_no, 0, sum(a.ordered), a.line_no -- v2.2
			FROM 	ord_list a (NOLOCK) 
			JOIN	inv_master b (NOLOCK) 
			ON		a.part_no = b.part_no 
			WHERE 	a.order_no = @order_no 
			AND		a.order_ext = @order_ext  
			AND		a.part_no = @part_no_in
			GROUP BY b.type_code, a.location, a.part_no, a.line_no
			
			-- v1.9 Start
			SELECT	@is_void = 1
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext
			AND		void = 'V'
			-- v1.9 End
		END
		ELSE
		BEGIN

			IF (@order_no > 0) -- v3.0 Start
			BEGIN
				INSERT	@temp
				SELECT	a.line_no, a.part_no, 0, a.qty, 0
				FROM	tdc_soft_alloc_tbl a (NOLOCK)
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext
				AND		a.part_no = @part_no_in
			END -- v3.0 End

			-- Get soft allocation quantities
			INSERT	@temp
			SELECT	a.line_no, a.part_no, CASE WHEN a.deleted = 1 THEN a.quantity * -1 ELSE a.quantity END, 0, change
			FROM	cvo_soft_alloc_det a (NOLOCK)
			WHERE	a.soft_alloc_no = @soft_alloc_no
			AND		a.part_no = @part_no_in

			-- If the allocated line has been changed then use the soft alloc quantity
			UPDATE	@temp
			SET		alloc_qty = 0
			WHERE	line_no IN (SELECT line_no FROM @temp WHERE changed <> 0)

			UPDATE	@temp
			SET		sa_qty = 0
			WHERE	line_no IN (SELECT line_no FROM @temp WHERE sa_qty < 0)

			INSERT  @temp_sum
			SELECT	line_no, part_no, SUM(sa_qty + alloc_qty)
			FROM	@temp
			GROUP BY line_no, part_no


			INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
			SELECT 	b.type_code, a.location, a.part_no, 0, sum(CASE WHEN a.deleted = 1 THEN 0 ELSE a.quantity END), a.line_no -- v2.2 
			FROM 	dbo.cvo_soft_alloc_det a (NOLOCK) 
			JOIN 	inv_master b (NOLOCK) 
			ON 		a.part_no = b.part_no 
			WHERE 	a.order_no = @order_no 
			AND 	a.order_ext = @order_ext 
			AND		a.soft_alloc_no = @soft_alloc_no
			AND		a.status NOT IN (-1, -2, -3)
			AND		a.kit_part = 0
			AND		a.part_no = @part_no_in
			GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2

			INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
			SELECT 	b.type_code, a.location, a.part_no, 0, sum(CASE WHEN a.deleted = 1 THEN 0 ELSE a.quantity END), a.line_no -- v2.2
			FROM 	dbo.cvo_soft_alloc_det a (NOLOCK) 
			JOIN 	inv_master b (NOLOCK) 
			ON 		a.part_no = b.part_no 
			LEFT JOIN @returndata c -- v2.2
			ON		a.location = c.location -- v2.2 
			AND		a.part_no = c.part_no -- v2.2
			AND		a.line_no = c.line_no -- v2.2
			WHERE 	a.order_no = @order_no 
			AND 	a.order_ext = @order_ext 
			AND		a.soft_alloc_no = @soft_alloc_no
			AND		a.status IN (-1)
			AND		a.kit_part = 0
			AND		a.part_no = @part_no_in
	-- v2.2		AND		a.part_no NOT IN (SELECT part_no FROM @returndata)
			GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2

			IF (@order_no > 0) -- v3.0 Start
			BEGIN
				INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
				SELECT	b.type_code, a.location, a.part_no, 0, sum(a.qty), a.line_no -- v2.2
				FROM 	tdc_soft_alloc_tbl a (NOLOCK) 
				JOIN	inv_master b (NOLOCK) 
				ON		a.part_no = b.part_no 
				LEFT JOIN @returndata c 
				ON		a.location = c.location
				AND		a.part_no = c.part_no
				AND		a.line_no = c.line_no -- v2.2
				WHERE 	a.order_no = @order_no 
				AND		a.order_ext = @order_ext 
				AND		c.part_no IS NULL
				AND		a.order_type = 'S'
				AND		a.order_no <> 0
				AND		a.part_no = @part_no_in
				GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2

				INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity, line_no) -- v2.2
				SELECT	b.type_code, a.location, a.part_no, 0, sum(a.ordered), a.line_no -- v2.2
				FROM 	ord_list a (NOLOCK) 
				JOIN	inv_master b (NOLOCK) 
				ON		a.part_no = b.part_no 
				LEFT JOIN @returndata c 
				ON		a.location = c.location
				AND		a.part_no = c.part_no
				AND		a.line_no = c.line_no -- v2.2
				WHERE 	a.order_no = @order_no 
				AND		a.order_ext = @order_ext 
				AND		c.part_no IS NULL
				AND		a.part_no = @part_no_in
				GROUP BY b.type_code, a.location, a.part_no, a.line_no -- v2.2
			END -- v3.0 End

			UPDATE	a
			SET		quantity = b.qty
			FROM	@returndata a
			JOIN	@temp_sum b
			ON		a.line_no = b.line_no
			AND		a.part_no = b.part_no
			

		END

	END
	-- v2.9 End

	-- v1.9 Start
	IF (@is_void = 0)
	BEGIN

		-- Update with the available quantites
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@part_no = part_no,
				@line_no = line_no -- v2.4
		FROM	@returndata
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			
			-- Get the instock figure
			-- v2.1 - Get replen qty as well
			-- v3.1 Start
--			SELECT	@instock = in_stock, @replen_qty = replen_qty from inventory where location = @location and part_no = @part_no
			SELECT	@instock = in_stock, 
					@replen_qty = replen_qty,
					@part_type = status -- v3.2 
			FROM	dbo.cvo_inventory2 
			WHERE	location = @location 
			AND		part_no = @part_no
			-- v3.1 End
			
			-- v3.2 Start
			IF (@part_type <> 'C')
			BEGIN

				-- Get the allocated and quarantined quantities
				DELETE	@tdc_data
				INSERT	@tdc_data EXEC tdc_get_alloc_qntd_sp @location, @part_no
				SELECT	@allocated = allocated_amt,
						@quarantine = quarantined_amt
				FROM	@tdc_data
				WHERE	location = @location
				AND		part_no = @part_no

				IF (@onload = 1)
				BEGIN
					-- Get qty soft allocated to other orders
					-- v2.8 Start
	--				SELECT	@soft_alloc_qty = SUM(quantity)
	--				FROM	dbo.cvo_soft_alloc_det (NOLOCK)
	--				WHERE	location = @location
	--				AND		part_no = @part_no
	--				AND		soft_alloc_no <> @soft_alloc_no
	--				-- START v1.2
	--				-- START v1.1 - ignore soft allocations for this order
	--				AND		NOT (order_no = @order_no AND order_ext = @order_ext)
	--				--AND		order_no <> @order_no
	--				--AND		order_ext <> @order_ext
	--				-- END v1.1
	--				-- END v1.2
	--				AND		status NOT IN (-2,-3)
	--				AND		soft_alloc_no < @soft_alloc_no
	--			--	AND		inv_avail IS NOT NULL -- v1.8


					SELECT	@soft_alloc_qty = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END) -- v1.4
					FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
					LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
					ON	a.order_no = b.order_no
					AND	a.order_ext = b.order_ext
					AND	a.part_no = b.part_no
					AND a.line_no = b.line_no
					WHERE	a.status NOT IN (-2,-3) -- v1.5 IN (0, 1, -1)
					AND		a.soft_alloc_no < @soft_alloc_no
					AND		a.location = @location
					AND		a.part_no = @part_no
					-- v2.8 End


					-- v2.5 Start
					SELECT	@ord_soft_alloc_qty = SUM(quantity)
					FROM	dbo.cvo_soft_alloc_det (NOLOCK)
					WHERE	location = @location
					AND		part_no = @part_no
					AND		soft_alloc_no = @soft_alloc_no
					AND		line_no < @line_no
					AND		status NOT IN (-2,-3)
					-- v2.5 End
				END
				ELSE
				BEGIN
					-- v2.8 Start
	--				SELECT	@soft_alloc_qty = SUM(quantity)
	--				FROM	dbo.cvo_soft_alloc_det (NOLOCK)
	--				WHERE	location = @location
	--				AND		part_no = @part_no
	--				AND		soft_alloc_no <> @soft_alloc_no
	--				-- START v1.2
	--				-- START v1.1 - ignore soft allocations for this order
	--				AND		NOT (order_no = @order_no AND order_ext = @order_ext)
	--				--AND		order_no <> @order_no
	--				--AND		order_ext <> @order_ext
	--				-- END v1.1
	--				-- END v1.2
	--				AND		status NOT IN (-2,-3)
	--				AND		soft_alloc_no < @soft_alloc_no
	--
	--			--	AND		inv_avail IS NOT NULL -- v1.8

					SELECT	@soft_alloc_qty = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END) -- v1.4
					FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
					LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
					ON	a.order_no = b.order_no
					AND	a.order_ext = b.order_ext
					AND	a.part_no = b.part_no
					AND a.line_no = b.line_no
					WHERE	a.status NOT IN (-2,-3) -- v1.5 IN (0, 1, -1)
					AND		a.soft_alloc_no < @soft_alloc_no
					AND		a.location = @location
					AND		a.part_no = @part_no
					-- v2.8 End

					-- v2.5 Start
					SELECT	@ord_soft_alloc_qty = SUM(quantity)
					FROM	dbo.cvo_soft_alloc_det (NOLOCK)
					WHERE	location = @location
					AND		part_no = @part_no
					AND		soft_alloc_no = @soft_alloc_no
					AND		line_no < @line_no
					AND		status NOT IN (-2,-3)
					-- v2.5 End

				END
				IF @soft_alloc_qty IS NULL
					SET @soft_alloc_qty = 0

				-- v2.5 Start
				IF @ord_soft_alloc_qty IS NULL
					SET @ord_soft_alloc_qty = 0
				-- v2.5 End

				-- START v1.1 - get qty hard allocated to this order
				SET @alloc_to_this_order = 0

				SELECT 
					@alloc_to_this_order = SUM(qty)  
				FROM
					dbo.tdc_soft_alloc_tbl (NOLOCK)
				WHERE
					order_no = @order_no 
					AND order_ext = @order_ext 
					AND order_type = 'S' 
					AND location = @location  
					AND part_no = @part_no
					AND	line_no = @line_no -- v2.4
					AND	order_no <> 0 -- v1.3

				-- v1.4 Start
				SET @qty_picked = 0

				-- START v2.3
				--IF (@onload = 1)
				--BEGIN

				SELECT	@qty_picked = SUM(shipped)
				FROM	tdc_dist_item_list (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @part_no
				AND		line_no = @line_no -- v2.4
				AND		[function] = 'S'

				IF @qty_picked IS NULL
					SET @qty_picked = 0

				--END
				-- END v2.3
				-- v1.4 End

				-- SELECT	@available = @instock - (@allocated + @quarantine) - ISNULL(@soft_alloc_qty,0)		
				SELECT @available = @instock - (@allocated + @quarantine) - ISNULL(@soft_alloc_qty,0) + ISNULL(@alloc_to_this_order,0) + @qty_picked - ISNULL(@replen_qty,0) - ISNULL(@ord_soft_alloc_qty,0) -- v1.1 v1.4 v2.1 v2.5
			
				-- v1.7 Start
				IF ((@available <= 0) AND (ISNULL(@alloc_to_this_order,0) > 0))
					SET @available = ISNULL(@alloc_to_this_order,0)
				-- v1.7 End

				-- START v2.6 
				IF @onload = 1
				BEGIN
					IF ISNULL(@available,0) < ISNULL(@alloc_to_this_order,0) 
					BEGIN
						SET @available = ISNULL(@alloc_to_this_order,0)
					END
				END
				-- END v2.6
				
				-- END v1.1

				IF @available < 0
					SET @available = 0

				UPDATE	@returndata
				SET		avail_quantity = CASE WHEN @available >= quantity THEN quantity ELSE @available END
				WHERE	row_id = @row_id
			END
			ELSE
			BEGIN
				UPDATE	@returndata
				SET		avail_quantity = quantity
				WHERE	row_id = @row_id
			END
			-- v3.2 End



			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@part_no = part_no,
					@line_no = line_no -- v2.4
			FROM	@returndata
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END

		-- v2.9 Start
		IF (@part_no_in IS NOT NULL)
		BEGIN
			IF EXISTS (SELECT 1 FROM @returndata WHERE quantity > avail_quantity AND part_no = @part_no_in)
				SELECT -1
			ELSE
				SELECT 0

			RETURN
		END
		-- v2.9 End

		-- START v2.7 - Loop through results and pull out unavailable parts
		SET @part_no = ''
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@part_no = part_no
			FROM
				@returndata
			WHERE
				part_no > @part_no
				AND quantity > avail_quantity
			ORDER BY
				part_no

			IF @@ROWCOUNT = 0
				BREAK
			
			IF @unavailable_parts = ''
			BEGIN
				SET @unavailable_parts = @part_no
			END
			ELSE
			BEGIN
				SET @unavailable_parts = @unavailable_parts + CHAR(13) + CHAR(10) + @part_no
			END
		END
		-- END v2.7

		-- v2.0 Start
		IF NOT EXISTS (SELECT 1 FROM @returndata WHERE type_code IN ('FRAME','SUN'))
		BEGIN
			SELECT	type_code + ' x ' +  LTRIM(STR(SUM(quantity))) + CASE WHEN (SUM(avail_quantity) < SUM(quantity)) THEN ' (' +  LTRIM(STR(SUM(quantity) - SUM(avail_quantity))) + ' unavailable)' ELSE '' END
			FROM	@returndata
			GROUP BY type_code
			HAVING SUM(quantity) <> 0
			-- START v2.7
			UNION  
			SELECT 'UNAVAILABLE_PARTS=' + ISNULL(@unavailable_parts,'') 
			-- END v2.7
		END
		ELSE
		BEGIN		

			-- START v1.5
			SELECT 
				@fill_rate = ROUND((SUM(avail_quantity) / SUM(quantity)) * 100,1)
			FROM
				@returndata	
			-- START v1.6
			WHERE
				type_code IN ('FRAME','SUN')
			-- END v1.6
			-- END v1.5

			-- return the summary data
			SELECT	type_code + ' x ' +  LTRIM(STR(SUM(quantity))) + CASE WHEN (SUM(avail_quantity) < SUM(quantity)) THEN ' (' +  LTRIM(STR(SUM(quantity) - SUM(avail_quantity))) + ' unavailable)' ELSE '' END
			FROM	@returndata
			GROUP BY type_code
			HAVING SUM(quantity) <> 0
			UNION
			SELECT	'FILL_RATE=' + CAST(ISNULL(@fill_rate,0) AS VARCHAR(20))
			-- START v2.7
		   UNION  
		   SELECT 'UNAVAILABLE_PARTS=' + ISNULL(@unavailable_parts,'') 
		   -- END v2.7
		END -- v2.0 End
	END
	ELSE
	BEGIN
		SELECT	type_code + ' x ' +  LTRIM(STR(SUM(quantity))) 
		FROM	@returndata
		GROUP BY type_code
		HAVING SUM(quantity) <> 0

	END
	-- v1.9 End
END
GO
GRANT EXECUTE ON  [dbo].[cvo_order_summary_sp] TO [public]
GO
