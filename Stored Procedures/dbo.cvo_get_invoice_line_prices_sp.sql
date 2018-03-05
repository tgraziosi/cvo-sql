SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_get_invoice_line_prices_sp]	@order_no int,
												@order_ext int,
												@line_no int,
												@cust_code varchar(10),
												@qty decimal(20,8),
												@gross_price decimal(20,8) OUTPUT,
												@discount_price decimal(20,8) OUTPUT,												
												@net_price decimal(20,8) OUTPUT,												
												@ext_net_price decimal(20,8) OUTPUT
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@IsBG			int,
			@IsPromo		int,
			@IsQuoted		int,
			@IsFixed		int,
			@IsList			int,
			@IsCust			int,
			@buying_group	varchar(10),
			@line_disc		decimal(20,8),
			@promo_id		varchar(20),
			@promo_level	varchar(20),
			@discount_perc	decimal(20,8),
			@customer_code	varchar(10), -- v1.2
			@part_no		varchar(30), -- v1.2
			@order_date		datetime, -- v1.2
			@quote_net_only char(1), -- v1.7
			@IsCredit		char(1) -- v1.9

	-- PROCESSING
	SELECT	@buying_group = ISNULL(buying_group,''),
			@promo_id = ISNULL(promo_id,''),
			@promo_level = promo_level
	FROM	cvo_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	-- v1.9 Start
	SELECT	@isCredit = CASE type WHEN 'C' THEN 'Y' ELSE 'N' END
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext
	-- v1.9 End

	SET @customer_code = @cust_code

	IF (@buying_group <> '')
		SET @cust_code = @buying_group

	SELECT	@IsBg = ISNULL(alt_location_code,0)
	FROM	arcust (NOLOCK)
	WHERE	customer_code = @cust_code

	SELECT	@line_disc = discount,
			@IsQuoted = CASE price_type WHEN 'Q' THEN 1 ELSE 0 END,
			@part_no = part_no, -- v1.2
			@order_date = time_entered -- v1.2
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		line_no = @line_no

	-- v1.2 Start
	IF (@IsQuoted = 1) -- v1.5 AND @IsBg = 1)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE customer_key = @customer_code AND ilevel = 0 
						AND item = @part_no AND start_date <= @order_date AND date_expires >= @order_date)
		BEGIN
			SET @IsQuoted = 0
		END
	END
	-- v1.2 End

	-- v1.7 Start
	SET @quote_net_only = 'N'
	IF (@IsQuoted = 1)
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE customer_key = @customer_code AND ilevel = 0 
						AND item = @part_no AND start_date <= @order_date AND date_expires >= @order_date AND net_only = 'Y')
		BEGIN
			SET @quote_net_only = 'Y'
		END
	END
	-- v1.7 End

	IF (@promo_id <> '')
	BEGIN
		SELECT	@IsPromo = 1,
				@IsFixed = CASE ISNULL(price_override,'N') WHEN 'Y' THEN 1 ELSE 0 END,
				@IsList = CASE ISNULL(list,'N') WHEN 'Y' THEN 1 ELSE 0 END,
				@IsCust = CASE ISNULL(cust,'N') WHEN 'Y' THEN 1 ELSE 0 END,
				@IsQuoted = 0
		FROM	cvo_line_discounts (NOLOCK)
		WHERE	promo_id = @promo_id
		AND		promo_level = @promo_level
	END
	ELSE
	BEGIN
		SET	@IsPromo = 0
		SET @IsFixed = 0
		SET @IsList = 0
		SET @IsCust = 0
	END

--select '@IsBg',@IsBg,'@IsQuoted',@IsQuoted,'@IsPromo',@IsPromo,'@IsFixed',@IsFixed,'@IsList',@IsList,'@IsCust',@IsCust
	
	IF (@IsBg = 1) -- BG
	BEGIN
		IF (@IsPromo = 0)
		BEGIN
			IF (@IsQuoted = 0)
			BEGIN

-- v1.3 Start
				IF (@line_disc <> 0) -- v1.4
				BEGIN
					SELECT	@gross_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@discount_price = 0,
							@discount_perc = 0,
							@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END
				ELSE
				BEGIN
					SELECT	@gross_price = ROUND(list_price,2),
							@discount_price = 0,
							@discount_perc = 0,
							@net_price = ROUND(list_price,2),
							@ext_net_price = (ROUND(list_price,2) * @qty)
					FROM	cvo_ord_list (NOLOCK)
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		line_no = @line_no
				END
-- v1.3 End

				RETURN
			END

			IF (@IsQuoted = 1)
			BEGIN
				-- v1.7 Start
				IF (@quote_net_only = 'N')
				BEGIN
					SELECT	@gross_price = CASE WHEN b.amt_disc = 0 THEN ROUND(b.list_price,2) ELSE ROUND(a.curr_price,2) END,
							@discount_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(b.list_price,2) - ROUND(a.curr_price,2)) ELSE ROUND(b.amt_disc,2) END,
							@discount_perc = 0,
							@net_price = CASE WHEN b.amt_disc = 0 THEN ROUND(a.curr_price,2) ELSE (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) END,
							@ext_net_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(a.curr_price,2) * @qty) ELSE ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty) END
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END
				ELSE -- v1.7 End
				BEGIN
					SELECT	@gross_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@discount_price = 0,
							@discount_perc = 0,
							@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END
			

				RETURN
			END
		END
		ELSE
		BEGIN
			IF (@IsQuoted = 0)
			BEGIN
				SELECT	@gross_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
						@discount_price = 0,
						@discount_perc = 0,
						@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
						@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext
				AND		a.line_no = @line_no

				RETURN
			END
			IF (@IsQuoted = 1)
			BEGIN
				-- v1.7 Start
				IF (@quote_net_only = 'N')
				BEGIN
					SELECT	@gross_price = CASE WHEN b.amt_disc = 0 THEN ROUND(b.list_price,2) ELSE ROUND(a.curr_price,2) END,
							@discount_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(b.list_price,2) - ROUND(a.curr_price,2)) ELSE ROUND(b.amt_disc,2) END,
							@discount_perc = 0,
							@net_price = CASE WHEN b.amt_disc = 0 THEN ROUND(a.curr_price,2) ELSE (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) END,
							@ext_net_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(a.curr_price,2) * @qty) ELSE ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty) END
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END
				ELSE -- v1.7 End
				BEGIN
					SELECT	@gross_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@discount_price = 0,
							@discount_perc = 0,
							@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END		

				RETURN
			END
		END
	END
	ELSE -- Non BG
	BEGIN
		IF (@IsPromo = 0)
		BEGIN
			IF (@IsQuoted = 0)
			BEGIN
				-- v1.6 Start
--				SELECT	@gross_price = ROUND(a.curr_price,2),
--						@discount_price = ROUND(b.amt_disc,2),
--						@discount_perc = a.discount,
--						@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
--						@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)

-- v1.8 Start
--				SELECT	@gross_price = ROUND(b.list_price,2),
--						@discount_price = ROUND(b.list_price,2) - ROUND(a.curr_price,2),
--						@discount_perc = a.discount,
--						@net_price = ROUND(a.curr_price,2), 
--						@ext_net_price = (ROUND(a.curr_price,2) * @qty)
				-- v1.6 End
				SELECT	@gross_price = CASE WHEN a.discount = 100 THEN ROUND(b.list_price,2) ELSE ROUND(b.list_price,2) END,
						@discount_price = CASE WHEN a.discount = 100 THEN ROUND(b.list_price,2) ELSE ROUND(b.list_price,2) - ROUND(a.curr_price,2) END,
						@discount_perc = a.discount,
						@net_price = CASE WHEN a.discount = 100 THEN 0 ELSE ROUND(a.curr_price,2) END, 
						@ext_net_price = CASE WHEN a.discount = 100 THEN 0 ELSE (ROUND(a.curr_price,2) * @qty) END
-- v1.8 End
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext
				AND		a.line_no = @line_no

				RETURN
			END
			IF (@IsQuoted = 1)
			BEGIN
				-- v1.7 Start
				IF (@quote_net_only = 'N')
				BEGIN

					SELECT	@gross_price = CASE WHEN b.amt_disc = 0 THEN ROUND(b.list_price,2) ELSE ROUND(a.curr_price,2) END,
							@discount_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(b.list_price,2) - ROUND(a.curr_price,2)) ELSE ROUND(b.amt_disc,2) END,
							@discount_perc = 0,
							@net_price = CASE WHEN b.amt_disc = 0 THEN ROUND(a.curr_price,2) ELSE (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) END,
							@ext_net_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(a.curr_price,2) * @qty) ELSE ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty) END
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END
				ELSE -- v1.7 End
				BEGIN
					SELECT	@gross_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@discount_price = 0,
							@discount_perc = 0,
							@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END

				RETURN
			END
		END
		ELSE
		BEGIN
			IF (@IsCust = 1)
			BEGIN				
				IF EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND curr_price = price AND curr_price = temp_price)
				BEGIN
-- v1.1 Start
--					SELECT	@gross_price = ROUND(a.curr_price,2),
--							@discount_price = ROUND(b.amt_disc,2),
--							@discount_perc = a.discount,
--							@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
--							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)

					SELECT	@gross_price = ROUND(b.list_price,2),
							@discount_price = ROUND(b.list_price,2) - (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)),
							@discount_perc = a.discount,
							@net_price = (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)),
							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty) -- v1.1 End
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no	

					RETURN		
				END
				ELSE
				BEGIN
					IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND amt_disc = 0)
					BEGIN
						SELECT	@gross_price = ROUND(a.temp_price,2),
								@discount_price = (ROUND(a.temp_price,2) - ROUND(a.curr_price,2)),
								@discount_perc = 0,
								@net_price = ROUND(a.curr_price,2),
								@ext_net_price = (ROUND(a.curr_price,2) * @qty)
						FROM	ord_list a (NOLOCK)
						JOIN	cvo_ord_list b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.order_ext = b.order_ext
						AND		a.line_no = b.line_no
						WHERE	a.order_no = @order_no
						AND		a.order_ext = @order_ext
						AND		a.line_no = @line_no
					END
					ELSE
					BEGIN
						SELECT	@gross_price = ROUND(b.list_price,2),
								@discount_price = ROUND(b.amt_disc,2),
								@discount_perc = a.discount,
								@net_price = (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)),
								@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
						FROM	ord_list a (NOLOCK)
						JOIN	cvo_ord_list b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.order_ext = b.order_ext
						AND		a.line_no = b.line_no
						WHERE	a.order_no = @order_no
						AND		a.order_ext = @order_ext
						AND		a.line_no = @line_no
					END
				END
		
				RETURN
			END
			IF (@IsQuoted = 0)
			BEGIN

-- v1.9 Start
--				SELECT	@gross_price = ROUND(a.curr_price,2),
--						@discount_price = ROUND(b.amt_disc,2),
--						@discount_perc = a.discount,
--						@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
--						@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
				SELECT	@gross_price = ROUND(a.curr_price,2),
						@discount_price = CASE @isCredit WHEN 'Y' THEN 0 ELSE ROUND(b.amt_disc,2) END,
						@discount_perc = CASE @isCredit WHEN 'Y' THEN 0 ELSE a.discount END,
						@net_price = ROUND(a.curr_price,2) - CASE @isCredit WHEN 'Y' THEN 0 ELSE ROUND(b.amt_disc,2) END,
						@ext_net_price = ((ROUND(a.curr_price,2) - CASE @isCredit WHEN 'Y' THEN 0 ELSE ROUND(b.amt_disc,2) END) * @qty)
-- v1.9 End
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext
				AND		a.line_no = @line_no

				RETURN
			END
			IF (@IsQuoted = 1)
			BEGIN
				-- v1.7 Start
				IF (@quote_net_only = 'N')
				BEGIN
					SELECT	@gross_price = CASE WHEN b.amt_disc = 0 THEN ROUND(b.list_price,2) ELSE ROUND(a.curr_price,2) END,
							@discount_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(b.list_price,2) - ROUND(a.curr_price,2)) ELSE ROUND(b.amt_disc,2) END,
							@discount_perc = 0,
							@net_price = CASE WHEN b.amt_disc = 0 THEN ROUND(a.curr_price,2) ELSE (ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) END,
							@ext_net_price = CASE WHEN b.amt_disc = 0 THEN (ROUND(a.curr_price,2) * @qty) ELSE ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty) END
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END
				ELSE -- v1.7 End
				BEGIN
					SELECT	@gross_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@discount_price = 0,
							@discount_perc = 0,
							@net_price = ROUND(a.curr_price,2) - ROUND(b.amt_disc,2),
							@ext_net_price = ((ROUND(a.curr_price,2) - ROUND(b.amt_disc,2)) * @qty)
					FROM	ord_list a (NOLOCK)
					JOIN	cvo_ord_list b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.line_no = @line_no
				END

				RETURN
			END
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_invoice_line_prices_sp] TO [public]
GO
