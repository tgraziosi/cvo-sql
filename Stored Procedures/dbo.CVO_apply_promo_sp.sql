SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 02/07/2013 - Created
v1.1 CB 16/07/2013 - Issue #927 - Buying Group Switching
v1.2 CT 19/11/2013 - Issue #1421 - Shipping Method is no longer linked to Free Shipping
v1.3 CB 19/06/2014 - Performance
*/
CREATE PROCEDURE [dbo].[CVO_apply_promo_sp]	@order_no		INT, 
										@ext			INT, 
										@promo_id		VARCHAR(20),
										@promo_level	VARCHAR(30)
																  
AS
BEGIN
	DECLARE @free_shipping		VARCHAR(1),
			@order_discount		DECIMAL(20,8),
			@payment_terms		VARCHAR(30),
			@shipping_method	VARCHAR(20),
			@disc_applied		SMALLINT,
			@line_no			INT,
			@curr_price			DECIMAL(20,8),
			@amt_disc			DECIMAL(20,8),
			@soft_alloc_no		INT,
			@customer_code		VARCHAR(10),
			@location			VARCHAR(10),
			@is_bg				SMALLINT,
			@disc_line_no		INT,
			@brand				VARCHAR(30),
			@category			VARCHAR(30),
			@discount_per		DECIMAL(20,8),
			@list				VARCHAR(1),
			@cust				VARCHAR(1),
			@price_override		CHAR(1),
			@price				DECIMAL(20,8),
			@price_type			CHAR(1),
			@list_price			DECIMAL(20,8),
			@disc_amt			DECIMAL(20,8),
			@part_no			VARCHAR(30),
			@orig_disc			DECIMAL(20,8),
			@status				VARCHAR(1),
			@tax_id				VARCHAR(10),
			@userid				VARCHAR(20),
			@back_ord_flag		CHAR(1),
			@ship_to_region		CHAR(2),
			@suser_sname		VARCHAR(1000),
			@charpos			SMALLINT,
			@parent				varchar(10), -- v1.1
			@order_date			varchar(10) -- v1.1

	SET NOCOUNT ON
	SET @disc_applied = 0

	-- Get user name
	SET @suser_sname = suser_sname()

	SELECT @charpos = CHARINDEX('\',@suser_sname,1)
	IF @charpos > 0 
	BEGIN
		SELECT @userid = RIGHT(@suser_sname,(LEN(@suser_sname) - @charpos))
	END
	ELSE
	BEGIN
		SELECT @userid = LEFT(@suser_sname,20)
	END

	-- Get order details
	SELECT
		@customer_code = cust_code,
		@location = location,
		@status = [status],
		@tax_id = tax_id,
		@back_ord_flag = back_ord_flag,
		@ship_to_region = LEFT(ship_to_region,2)
	FROM
		dbo.orders_all (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	-- Get promo header details
	SELECT 	
		@free_shipping = free_shipping, 		
		@order_discount = order_discount, 	
		@payment_terms = payment_terms, 
		@shipping_method = shipping_method
	FROM 	
		dbo.CVO_promotions (NOLOCK)
	WHERE 
		promo_id = @promo_id 
		AND promo_level = @promo_level

	-- Order discount
	IF ISNULL(@order_discount,0) <> 0
	BEGIN
		SET @disc_applied = 1
		
		-- Apply discount to all lines
		SET @line_no = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1 
				@line_no = line_no,
				@curr_price = curr_price
			FROM
				dbo.ord_list (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no > @line_no
			ORDER BY
				line_no

			IF @@ROWCOUNT = 0
				BREAK

			-- Calc discount amount
			SET @amt_disc = ROUND(@curr_price * (@order_discount/100),2)

			-- Update line
			UPDATE
				dbo.ord_list WITH (ROWLOCK)
			SET
				discount = @order_discount
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			UPDATE
				dbo.cvo_ord_list  WITH (ROWLOCK)
			SET
				amt_disc = @amt_disc,
				is_amt_disc = CASE @amt_disc WHEN 0 THEN 'N' ELSE 'Y' END
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

		END
	END

	-- Line discounts
	IF @disc_applied = 0
	BEGIN
		-- Check buying group setting
		SET @is_bg = 0
		-- v1.1 Start
		SELECT	@order_date = CONVERT(varchar(10),date_entered,121) FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext
		SELECT	@parent = dbo.f_cvo_get_buying_group(@customer_code,@order_date)
		IF (@parent IS NULL OR @parent = '')
			SET @is_bg = 0
		ELSE
			SET @is_bg = 1

--		IF EXISTS (SELECT 1 FROM dbo.armaster_all a (NOLOCK) INNER JOIN	dbo.artierrl b (NOLOCK) ON a.customer_code = b.parent 
--						WHERE	a.addr_sort1 = 'Buying Group' AND a.address_type = 0 AND b.rel_cust = @customer_code)
--		BEGIN
--			SET @is_bg = 1
--		END
		-- v1.1 End

		-- Loop through promo line discounts
		SET @disc_line_no = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@disc_line_no = line_no,   
				@brand = brand,   
				@category = category,   
				@discount_per = discount_per,   
				@list = list,   
				@cust = cust,
				@price_override = price_override,
				@price = price 
			FROM 
				dbo.CVO_line_discounts (NOLOCK)
			WHERE 
				promo_ID = @promo_id 
				AND promo_level = @promo_level
				AND line_no > @disc_line_no
			ORDER BY
				line_no

			IF @@ROWCOUNT = 0
				BREAK

			-- Loop through order lines and apply as applicable
			SET @line_no = 0
			WHILE 1=1
			BEGIN
				SELECT TOP 1 
					@line_no = a.line_no,
					@curr_price = a.curr_price,
					@price_type = a.price_type,
					@part_no = a.part_no
				FROM
					dbo.ord_list a (NOLOCK)
				INNER JOIN	
					dbo.inv_master b (NOLOCK)
				ON
					a.part_no = b.part_no
				WHERE
					a.order_no = @order_no
					AND a.order_ext = @ext
					AND a.line_no > @line_no
					AND ((ISNULL(@brand,'') = '') OR (ISNULL(@brand,'') <> '' AND b.category = @brand))
					AND ((ISNULL(@category,'') = '') OR (ISNULL(@category,'') <> '' AND b.type_code = @category))
					AND a.price_type NOT IN ('X','Y')
				ORDER BY
					a.line_no

				IF @@ROWCOUNT = 0
					BREAK

				IF ISNULL(@price_override,'N') = 'Y'
				BEGIN
					IF @is_bg = 1
					BEGIN
						
						UPDATE 
							dbo.ord_list  WITH (ROWLOCK)
						SET
							curr_price = @price,
							oper_price = @price,
							price = @price,
							price_type = 'Y'
						WHERE
							order_no = @order_no
							AND order_ext = @ext
							AND line_no = @line_no

						UPDATE 
							dbo.cvo_ord_list  WITH (ROWLOCK)
						SET
							list_price = @price,
							is_amt_disc = 'N'
						WHERE
							order_no = @order_no
							AND order_ext = @ext
							AND line_no = @line_no
					END
					ELSE
					BEGIN
						UPDATE 
							dbo.ord_list  WITH (ROWLOCK)
						SET
							curr_price = @price,
							oper_price = @price,
							price = @price,
							price_type = 'Y'
						WHERE
							order_no = @order_no
							AND order_ext = @ext
							AND line_no = @line_no

						UPDATE 
							dbo.cvo_ord_list  WITH (ROWLOCK)
						SET
							is_amt_disc = 'N'
						WHERE
							order_no = @order_no
							AND order_ext = @ext
							AND line_no = @line_no
					END
				END
				ELSE
				BEGIN -- @price_override = 'N'
					-- Get list price
					SELECT
						@list_price = b.price
					FROM
						adm_inv_price a (NOLOCK)
					INNER JOIN 
						adm_inv_price_det b (NOLOCK)
					ON 
						a.inv_price_id = b.inv_price_id
					WHERE
						a.part_no = @part_no
						AND a.active_ind = 1

					IF ISNULL(@list,'N') = 'Y'
					BEGIN
						IF ISNULL(@list_price,0) > 0
						BEGIN
							SET @disc_amt = ROUND(@list_price * (@discount_per/100),2)

							IF @is_bg = 1
							BEGIN
								UPDATE 
									dbo.ord_list  WITH (ROWLOCK)
								SET
									discount = 0,
									curr_price = @list_price - @disc_amt,
									oper_price =  @list_price - @disc_amt,
									price =  @list_price - @disc_amt,
									price_type = '1'
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no

								UPDATE 
									dbo.cvo_ord_list  WITH (ROWLOCK)
								SET
									list_price =  @list_price - @disc_amt,
									is_amt_disc = 'N',
									amt_disc = 0
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no
							END
							ELSE	
							BEGIN
								UPDATE 
									dbo.ord_list  WITH (ROWLOCK)
								SET
									discount = @discount_per,
									curr_price = @list_price,
									price_type = '1'
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no

								UPDATE 
									dbo.cvo_ord_list  WITH (ROWLOCK)
								SET
									is_amt_disc = 'Y',
									amt_disc = @disc_amt
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no
							END
		
						END
						ELSE
						BEGIN  -- list_price = 0

							UPDATE 
								dbo.ord_list  WITH (ROWLOCK)
							SET
								discount = 0,
								curr_price = 0
							WHERE
								order_no = @order_no
								AND order_ext = @ext
								AND line_no = @line_no

							UPDATE 
								dbo.cvo_ord_list  WITH (ROWLOCK)
							SET
								amt_disc = 0
							WHERE
								order_no = @order_no
								AND order_ext = @ext
								AND line_no = @line_no


						END
					END
					ELSE
					BEGIN -- @list = 'N' (customer pricing)
						IF @is_bg = 1
						BEGIN
							IF ISNULL(@list_price,0) > 0
							BEGIN
							
								SET @orig_disc = ROUND((1 - (@curr_price / @list_price)) * 100,2)
								SET @disc_amt = ROUND(@list_price * (@discount_per/100),2)

								UPDATE 
									dbo.ord_list  WITH (ROWLOCK)
								SET
									curr_price = @list_price - @disc_amt,
									oper_price =  @list_price - @disc_amt,
									price =  @list_price - @disc_amt,
									discount = @orig_disc,
									price_type = '1'
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no

								UPDATE 
									dbo.cvo_ord_list  WITH (ROWLOCK)
								SET
									list_price =  @list_price - @disc_amt,
									amt_disc = @disc_amt,
									is_amt_disc = 'N'
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no

							END
							ELSE
							BEGIN
								UPDATE 
									dbo.ord_list  WITH (ROWLOCK)
								SET
									curr_price = 0,
									discount = 0
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no

								UPDATE 
									dbo.cvo_ord_list  WITH (ROWLOCK)
								SET
									amt_disc = 0,
									is_amt_disc = 'N'
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @line_no

							END
						END
						ELSE
						BEGIN
							SET @disc_amt = ROUND(@curr_price * (@discount_per/100),2)

							UPDATE 
								dbo.ord_list  WITH (ROWLOCK)
							SET
								discount = @discount_per
							WHERE
								order_no = @order_no
								AND order_ext = @ext
								AND line_no = @line_no

							UPDATE 
								dbo.cvo_ord_list  WITH (ROWLOCK)
							SET
								amt_disc = @disc_amt,
								is_amt_disc = 'Y'
							WHERE
								order_no = @order_no
								AND order_ext = @ext
								AND line_no = @line_no

						END
					END		
				END
			END  -- order line loop
		END -- promo line loop
	END

	-- Promo gifts
	-- Get soft alloc number
	EXEC CVO_get_soft_alloc_no_sp @order_no, @ext, @soft_alloc_no OUTPUT


	EXEC dbo.cvo_soft_alloc_add_promo_sp	@soft_alloc_no, @order_no, @ext, @customer_code,  
											@location, @promo_id, @promo_level
	
	-- If any promo gifts were added then create table entries
	IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND line_no = -1)
	BEGIN
		EXEC cvo_soft_alloc_apply_sp @soft_alloc_no, @order_no, @ext, @status, @userid, @back_ord_flag, @ship_to_region ,@tax_id
	END

	-- Free frames
	EXEC dbo.CVO_apply_free_frames_sp	@order_no, @ext, @promo_id,	@promo_level, @soft_alloc_no

	-- Update order
	UPDATE
		dbo.cvo_orders_all  WITH (ROWLOCK)
	SET
		promo_id = @promo_id,
		promo_level = @promo_level,
		free_shipping = CASE ISNULL(@free_shipping,'') WHEN '' THEN free_shipping ELSE @free_shipping END
	WHERE
		order_no = @order_no
		AND ext = @ext		

	UPDATE
		dbo.orders_all  WITH (ROWLOCK)
	SET
		discount = CASE @disc_applied WHEN 1 THEN @order_discount ELSE discount END,
		terms = CASE ISNULL(@payment_terms,'') WHEN '' THEN terms ELSE @payment_terms END,
		-- START v1.2
		routing = CASE ISNULL(@shipping_method,'') WHEN '' THEN routing ELSE @shipping_method END
		--routing = CASE ISNULL(@free_shipping,'N') WHEN 'Y' THEN (CASE ISNULL(@shipping_method,'') WHEN '' THEN routing ELSE @shipping_method END) ELSE routing END
		-- END v1.2
	WHERE
		order_no = @order_no
		AND ext = @ext

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[CVO_apply_promo_sp] TO [public]
GO
