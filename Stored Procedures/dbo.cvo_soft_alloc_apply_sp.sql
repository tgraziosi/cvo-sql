SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_apply_sp]	@soft_alloc_no	int,
										@order_no		int,	
										@order_ext		int,
										@status			char(1),
										@userid			varchar(20),
										@back_ord_flag  char(1),
										@ship_to_region char(2), -- left 2 characters
										@tax_code		varchar(8)
AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE @max_line		int,
			@id				int,
			@last_id		int,
			@gl_rev_acct	varchar(32),
			@part_no		varchar(30),
			@location		varchar(10),
			@row_id			int,
			@customer_code	varchar(10),
			@ship_to		varchar(10),
			@qty			decimal(20,8), -- v1.6
			@avail_qty		decimal(20,8), -- v1.6
			@sa_qty			decimal(20,8), -- v1.6
			@inv_avail		smallint, -- v1.6
			@max_sa_line	int, -- v2.3
			@max_display_line INT -- v2.5

	-- This routine is called on the order save event
	-- It adds all the extra lines added to the soft allocation to the actual order
	-- For each line where the line_no is zero add it to ord_list and cvo_ord_list	

	-- v1.1 Start
	IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND RIGHT(user_category,2) = 'RB')
	BEGIN
		DELETE	cvo_soft_alloc_hdr WHERE soft_alloc_no = @soft_alloc_no
		DELETE	cvo_soft_alloc_det WHERE soft_alloc_no = @soft_alloc_no
		RETURN
	END
	-- v1.1 End

	-- Create a working table
	CREATE TABLE #soft_alloc_detail (
			id				int IDENTITY(1,1),
			soft_alloc_no	int NOT NULL,
			order_no		int NOT NULL,
			order_ext		int NOT NULL,
			line_no			int NOT NULL,
			location		varchar(10) NOT NULL,
			part_no			varchar(30) NOT NULL,
			quantity		decimal(20,8) NOT NULL,
			is_case			smallint NOT NULL, 
			is_pattern		smallint NOT NULL, 
			is_pop_gift		smallint NOT NULL,
			gl_rev_acct		varchar(32),
			row_id			int,
			customer_code	varchar(10),
			ship_to			varchar(10),
			display_line	INT)  -- v2.5

	CREATE TABLE #soft_alloc_qty (qty	decimal(20,8)) -- v1.6


	-- Insert the data to process
	INSERT	#soft_alloc_detail (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity, is_case, is_pattern, is_pop_gift, row_id)
	SELECT	soft_alloc_no, order_no, order_no, line_no, location, part_no, quantity, is_case, is_pattern, is_pop_gift, row_id
	FROM	dbo.cvo_soft_alloc_det (NOLOCK)
	WHERE	soft_alloc_no = @soft_alloc_no
	AND		line_no <= 0
	AND		deleted = 0 -- v1.5

	-- If not record then exit
	IF @@ROWCOUNT > 0
	BEGIN

		-- Get the last line number on the order
		SELECT	@max_line = ISNULL(MAX(line_no),0) + 1
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		-- START v2.5
		SELECT	@max_display_line = ISNULL(MAX(display_line),0) + 1
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF @max_display_line IS NULL
			SET @max_display_line = 1
		-- END v2.5

		IF @max_line IS NULL
			SET @max_line = 1
		
		-- v2.3 Start
		SELECT	@max_sa_line = ISNULL(MAX(line_no),0) + 1
		FROM	cvo_soft_alloc_det (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF @max_sa_line IS NULL
			SET @max_sa_line = 1

		IF (@max_sa_line > @max_line)
			SET @max_line = @max_sa_line
		-- v2.3 End

		-- Assign the line numbers
		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@part_no = part_no,
				@location = location,
				@row_id = row_id,
				@qty = quantity -- v1.6
		FROM	#soft_alloc_detail
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			SELECT	@gl_rev_acct = a.sales_acct_code
			FROM	inv_list i (nolock)
			JOIN	in_account a (nolock)
			ON		a.acct_code = i.acct_code
			WHERE	i.part_no = @part_no
			AND		i.location = @location
			AND		( i.void is null or i.void = 'N' )
			
			SET @gl_rev_acct = SUBSTRING(@gl_rev_acct,1,4) + @ship_to_region + SUBSTRING(@gl_rev_acct,7,7) 

			UPDATE	#soft_alloc_detail
			SET		line_no = @max_line,
					display_line = @max_display_line, -- v2.5
					gl_rev_acct = @gl_rev_acct
			WHERE	id = @id

			-- v1.6 Start
			EXEC @avail_qty = CVO_CheckAvailabilityInStock_sp  @part_no, @location

			INSERT #soft_alloc_qty
			EXEC dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @part_no

			SELECT @sa_qty = qty FROM #soft_alloc_qty

			DELETE #soft_alloc_qty

			IF (@qty <= (@avail_qty - (@sa_qty - @qty))) -- v1.8
				SET @inv_avail = 1
			ELSE
				SET @inv_avail = NULL
			-- v1.1 End

			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		line_no = @max_line,
					inv_avail = @inv_avail -- v1.6
			WHERE	row_id = @row_id

			SET @max_line = @max_line + 1
			SET @max_display_line = @max_display_line + 1 -- v2.5

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@part_no = part_no,
					@location = location,
					@row_id = row_id,
					@qty = quantity -- v1.6
			FROM	#soft_alloc_detail
			WHERE	id > @last_id
			ORDER BY id ASC
		END

		-- Update the soft allocation records to add the order number
		UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
		SET		order_no = @order_no,
				order_ext = @order_ext
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		order_no = 0

		-- Update the soft allocation records to add the order number
		UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
		SET		order_no = @order_no,
				order_ext = @order_ext
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		order_no = 0

		-- v3.1 Start
		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_no_assign (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			INSERT	cvo_soft_alloc_no_assign  WITH (ROWLOCK) (order_no, order_ext, soft_alloc_no)
			VALUES (@order_no, @order_ext, @soft_alloc_no)
		END
		-- v3.1 End

		-- Update the soft allocation records to add the order number
		UPDATE	#soft_alloc_detail
		SET		order_no = @order_no,
				order_ext = @order_ext

		-- Pattern tracking
		IF EXISTS (SELECT 1 FROM #soft_alloc_detail WHERE is_pattern = 1)
		BEGIN
			SELECT	@customer_code = cust_code,
					@ship_to = ship_to
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no

			UPDATE	#soft_alloc_detail
			SET		customer_code = @customer_code,
					ship_to = @ship_to
			WHERE	is_pattern = 1

			IF EXISTS (SELECT 1 FROM dbo.cvo_armaster_all (NOLOCK) WHERE customer_code = @customer_code AND ISNULL(patterns_foo,0) = 1)
			BEGIN
				INSERT	dbo.cvo_pattern_tracking  WITH (ROWLOCK)(customer_code, ship_to, pattern, order_no, order_ext, line_no)
				SELECT	a.customer_code, a.ship_to, a.part_no, a.order_no, a.order_ext, a.line_no 
				FROM	#soft_alloc_detail a
				LEFT JOIN cvo_pattern_tracking b (NOLOCK)
				ON		a.customer_code = b.customer_code
				AND		a.ship_to = b.ship_to
				AND		a.part_no = b.pattern
				WHERE	a.is_pattern = 1
				AND		b.pattern IS NULL

			END
		END

		-- Insert ord_list records

		INSERT INTO dbo.ord_list  WITH (ROWLOCK) (order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price,
									price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped,
									discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor,
									direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, part_type,
									orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line,
									std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to,
									service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
									cust_po, organization_id, picked_dt, who_picked_id, printed_dt, who_unpicked_id, unpicked_dt)
		SELECT	@order_no, @order_ext, a.line_no, a.location, a.part_no, b.description, getdate(), a.quantity, 
				0, -- shipped 
				0.0, -- price
				CASE WHEN a.is_pop_gift = 2 THEN 'A' ELSE 'Y' END, -- price_type
				'', -- note  
				@status, c.std_cost, @userid, 
				0.0, -- sales _comm
				0.0, -- temp_price
				1, -- temp_type
				0, -- cr_ordered
				0, -- cr_shipped
				0.0, -- discount
				b.uom, 
				1.0, -- conv_factor
				'N', -- void
				NULL, -- void_who
				NULL, -- void_date
				0.0, -- std_cost
				0.0, -- cubic_feet
				'N', -- printed
				b.lb_tracking,
				c.std_labor, c.std_direct_dolrs, c.std_ovhd_dolrs, c.std_util_dolrs, b.taxable, b.weight_ea, b.qc_flag,
				NULL, -- reason_code
				0, -- qc_no,
				0.0, -- rejected
				b.status,
				a.part_no, @back_ord_flag, @gl_rev_acct,
				0.0, -- total_tax
				@tax_code, 
				0.0, -- curr_price
				0.0, -- oper_price
				-- START v2.5
				--a.line_no, 
				ISNULL(a.display_line,a.line_no), -- display_line
				-- END v2.5
				c.std_direct_dolrs, c.std_ovhd_dolrs, c.std_util_dolrs,
				NULL, -- reference_code
				'', -- contract
				NULL, -- agreement_id
				NULL, -- ship_to
				'N', -- service_agreement_flag
				'Y', -- inv_available_flag
				0, -- create_po
				NULL, NULL, NULL, NULL, --load_group_no, return_code, user_count, cust_po
				'CVO', -- organisation_id
				NULL, NULL, NULL, NULL, NULL --picked_dt, who_picked_id, printed_dt, who_unpicked_id, unpicked_dt
		FROM	#soft_alloc_detail a
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		JOIN	inv_list c (NOLOCK)
		ON		a.location = c.location
		AND		a.part_no = c.part_no

		-- START v2.0
		DELETE 
			a
		FROM 
			dbo.CVO_ord_list a 
		INNER JOIN 
			#soft_alloc_detail b
		ON
			a.line_no = b.line_no
		WHERE
			a.order_no = @order_no
			AND a.order_ext = @order_ext
		-- END v2.0
			
		-- Insert the cvo_ord_list record
		INSERT INTO dbo.CVO_ord_list  WITH (ROWLOCK) (order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized,
											is_polarized, is_pop_gif, is_amt_disc, amt_disc, is_customized, promo_item, list_price, free_frame) -- v2.6
		SELECT	@order_no, @order_ext, a.line_no, 'N', 'N', 0, a.is_case, a.is_pattern, 'N', 0, CASE WHEN a.is_pop_gift = 1 THEN a.is_pop_gift ELSE 0 END, 
				'N', 0.0, 'N', CASE WHEN a.is_pop_gift = 2 THEN 'Y' ELSE 'N' END, 0.0, 0 -- v2.6
		FROM	#soft_alloc_detail a

		-- v1.7 Start
		DELETE	a
		FROM	dbo.ord_list a --(NOLOCK) v2.9
		JOIN	dbo.cvo_soft_alloc_det b (NOLOCK) -- v2.9
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		AND		a.part_no = b.part_no -- v3.4
		WHERE	b.soft_alloc_no = @soft_alloc_no
		AND		b.status IN (-3, 0, 1)
		AND		(a.ordered = 0 OR b.deleted = 1) -- v1.4

		DELETE	dbo.cvo_soft_alloc_det
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		status IN (-3, 0, 1)
		AND		deleted = 1
		AND		change = 0
		-- v1.7 End
	END
--	ELSE -- v2.4
	BEGIN -- Update or delete


		-- v3.1 Start
		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_no_assign (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			INSERT	cvo_soft_alloc_no_assign  WITH (ROWLOCK) (order_no, order_ext, soft_alloc_no)
			VALUES (@order_no, @order_ext, @soft_alloc_no)
		END
		-- v3.1 End

		-- Update the soft allocation records to add the order number
		-- v3.2 Start
		IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND who_entered = 'BACKORDR')
		BEGIN
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		order_no = @order_no,
					order_ext = @order_ext,
					bo_hold = 1
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		(order_no = 0 OR bo_hold = 1) -- v2.8
		END
		ELSE
		BEGIN
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		order_no = @order_no,
					order_ext = @order_ext,
					bo_hold = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		(order_no = 0 OR bo_hold = 1) -- v2.8
		END
		-- v3.2 End

		-- Update the soft allocation records to add the order number
		UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
		SET		order_no = @order_no,
				order_ext = @order_ext
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		order_no = 0

		-- v2.7 Start
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

		INSERT	@temp
		SELECT	a.line_no, a.part_no, 0, a.qty, 0
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext

		-- Get soft allocation quantities
		INSERT	@temp
		SELECT	a.line_no, a.part_no, CASE WHEN a.deleted = 1 THEN a.quantity * -1 ELSE a.quantity END, 0, change
		FROM	cvo_soft_alloc_det a (NOLOCK)
		WHERE	a.soft_alloc_no = @soft_alloc_no

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
		-- v2.7 End

		UPDATE	a
		SET		ordered = (CASE WHEN b.deleted = 1 THEN (ordered - b.quantity) ELSE b.quantity END)
		FROM	dbo.ord_list a  WITH (ROWLOCK) -- (NOLOCK) v2.9
		JOIN	dbo.cvo_soft_alloc_det b (NOLOCK) -- v2.9
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		AND		a.part_no = b.part_no -- v3.7
		JOIN	@temp_sum c -- v2.7
		ON		a.line_no = c.line_no -- v2.7
		WHERE	b.soft_alloc_no = @soft_alloc_no
		AND		b.status IN (-3, 0, 1)
		AND		a.ordered <> (CASE WHEN b.deleted = 1 THEN (b.quantity * -1) ELSE b.quantity END)
		AND		a.ordered <> c.qty -- v2.7
		AND		b.change <=1 -- v2.1

		DELETE	a
		FROM	dbo.ord_list a --(NOLOCK) v2.9
		JOIN	dbo.cvo_soft_alloc_det b (NOLOCK) -- v2.9
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		AND		a.part_no = b.part_no -- v3.4
		WHERE	b.soft_alloc_no = @soft_alloc_no
		AND		b.status IN (-3, 0, 1)
		-- START v1.9
		AND		(a.ordered = 0 OR (b.deleted = 1 AND (a.ordered = b.quantity OR b.quantity = 0))) -- v1.9
		--AND	(a.ordered = 0 OR b.deleted = 1) -- v1.4
		AND		b.change <=1 -- v2.1
		-- END v1.9

		-- v1.4 Start
		DELETE	dbo.cvo_soft_alloc_det
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		status IN (-3, 0, 1)
		AND		deleted = 1
		AND		change = 0
		-- v1.4 End

		-- START v2.1
		UPDATE
			dbo.cvo_soft_alloc_det WITH (ROWLOCK)
		SET
			change = 2
		WHERE	
			soft_alloc_no = @soft_alloc_no
			AND status IN (-3, 0, 1)
			AND change = 1
		-- END v2.1

	END
	-- Clean up
	DROP TABLE #soft_alloc_detail

	-- v1.2 Start
	DELETE	a 
	FROM	cvo_soft_alloc_det a
	LEFT JOIN	
			ord_list b (NOLOCK) -- v2.9
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		a.part_no = b.part_no
	WHERE	a.soft_alloc_no = @soft_alloc_no
	AND		b.line_no IS NULL
    AND		a.kit_part = 0
	AND		a.deleted <> 1 -- v1.3

	-- v1.2 End

	-- v3.0 Start
	DELETE	cvo_ord_list_fc
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	
	INSERT	dbo.cvo_ord_list_fc  WITH (ROWLOCK) (order_no, order_ext, line_no, part_no, case_part, pattern_part)
	SELECT	a.order_no, a.order_ext, a.line_no, a.part_no, ISNULL(inv.field_1,''), ISNULL(inv.field_4,'')
	FROM	ord_list a (NOLOCK)
	JOIN	inv_master b (NOLOCK)
	ON		a.part_no = b.part_no
	JOIN	inv_master_add inv (NOLOCK)
	ON		b.part_no = inv.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext	
	AND		b.type_code IN ('FRAME','SUN')
	ORDER BY a.order_no, a.order_ext, a.line_no
	-- v3.0 End

	-- v3.5 Start - Add polarized_part
	UPDATE	a
	SET		polarized_part = c.part_no
	FROM	cvo_ord_list_fc a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no -- v3.9 b.from_line_no
	JOIN	ord_list c (NOLOCK)
	ON		b.order_no = c.order_no
	AND		b.order_ext = c.order_ext
	AND		b.line_no = c.cust_po -- v3.9 c.line_no
	JOIN	cvo_ord_list d (NOLOCK)
	ON		a.order_no = d.order_no
	AND		a.order_ext = d.order_ext
	AND		a.line_no = d.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		d.add_polarized = 'Y'

	UPDATE	cvo_ord_list
	SET		from_line_no = 0
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		from_line_no > 0
	-- v3.5 End

	-- v3.6 Start
	EXEC dbo.cvo_add_promo_discount_line_sp	@order_no, @order_ext
	-- v3.6 End

	-- v3.8 Start
	DELETE	a
	FROM	cvo_ord_list a
	LEFT JOIN ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.line_no IS NULL
	-- v3.8 End

END
GO

GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_apply_sp] TO [public]
GO
