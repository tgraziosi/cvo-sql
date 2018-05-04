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
			-- v2.5 Start
			IF NOT EXISTS (SELECT 1 FROM dbo.c_quote a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.item = b.category 
						WHERE a.customer_key = @customer_code AND a.ilevel = 1 
						AND b.part_no = @part_no AND a.start_date <= @order_date AND a.date_expires >= @order_date)
			BEGIN
			-- v2.5 End
				SET @IsQuoted = 0
			END
		END
	END
	-- v1.2 End

	-- v1.7 Start
	SET @quote_net_only = 'N'
	IF EXISTS (SELECT 1 FROM dbo.c_quote (NOLOCK) WHERE customer_key = @customer_code AND ilevel = 0 
					AND item = @part_no AND start_date <= @order_date AND date_expires >= @order_date AND net_only = 'Y')
	BEGIN
		SET @quote_net_only = 'Y'
	END
	-- v1.7 End
	-- v2.5 Start
	IF EXISTS (SELECT 1 FROM dbo.c_quote a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.item = b.category 
						WHERE a.customer_key = @customer_code AND a.ilevel = 1 
						AND b.part_no = @part_no AND a.start_date <= @order_date AND a.date_expires >= @order_date AND net_only = 'Y')
	BEGIN
		SET @quote_net_only = 'Y'
	END
	-- v2.5 End

	IF (@promo_id <> '')
	BEGIN
		SELECT	@IsPromo = 1,
				@IsFixed = CASE ISNULL(price_override,'N') WHEN 'Y' THEN 1 ELSE 0 END--,
--				@IsList = CASE ISNULL(list,'N') WHEN 'Y' THEN 1 ELSE 0 END,
--				@IsCust = CASE ISNULL(cust,'N') WHEN 'Y' THEN 1 ELSE 0 END,
--				@IsQuoted = 0
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
		-- v2.0 Start
		IF (@IsPromo = 0)
		BEGIN
			SELECT	@discount_perc = discount
			FROM	ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no

			IF (@discount_perc <> 0)
			BEGIN
				SELECT	@gross_price = (a.curr_price - ROUND(b.amt_disc,2)),
						@discount_price = 0,
						@net_price = (a.curr_price - ROUND(b.amt_disc,2)),
						@ext_net_price = (a.curr_price - ROUND(b.amt_disc,2)) * @qty
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
				-- v2.1 Start
				IF (@quote_net_only = 'N')
				BEGIN
					SELECT	@gross_price = b.list_price,
							@discount_price = 0,
							@net_price = b.list_price,
							@ext_net_price = (b.list_price * @qty)
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
					SELECT	@gross_price = a.curr_price,
							@discount_price = 0,
							@net_price = a.curr_price,
							@ext_net_price = (a.curr_price * @qty)
							FROM	ord_list a (NOLOCK)
							JOIN	cvo_ord_list b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.order_ext = b.order_ext
							AND		a.line_no = b.line_no
							WHERE	a.order_no = @order_no
							AND		a.order_ext = @order_ext
							AND		a.line_no = @line_no
				END
				-- v2.1 End
				RETURN
			END
		END
		ELSE
		BEGIN
			-- v2.2 Start
			IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN cvo_ord_list b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.order_ext
						AND a.line_no = b.line_no WHERE	a.order_no = @order_no AND a.order_ext = @order_ext AND a.line_no = @line_no
						AND	a.curr_price = 0 AND b.list_price = 0 AND b.is_case = 0 AND b.is_pattern = 0 AND b.is_polarized = 0 AND b.is_pop_gif = 0)
			BEGIN
				SELECT	@gross_price = b.orig_list_price,
						@discount_price = b.orig_list_price,
						@net_price = 0,
						@ext_net_price = 0
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
			-- v2.2 End

			-- v2.1 Start
			IF (@IsQuoted = 0)
			BEGIN
				SELECT	@gross_price = CASE WHEN (a.discount = 100 OR a.discount = 0) THEN b.list_price ELSE (a.curr_price - ROUND(b.amt_disc,2)) END,
						@discount_price = CASE WHEN a.discount = 100 THEN b.list_price ELSE 0 END,
						@net_price = CASE WHEN (a.discount = 0) THEN b.list_price ELSE (a.curr_price - ROUND(b.amt_disc,2)) END,
						@ext_net_price = (CASE WHEN (a.discount = 0) THEN b.list_price ELSE (a.curr_price - ROUND(b.amt_disc,2)) END) * @qty
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
				SELECT	@gross_price = CASE WHEN a.discount = 100 THEN b.list_price ELSE (a.curr_price - ROUND(b.amt_disc,2)) END,
						@discount_price = CASE WHEN a.discount = 100 THEN b.list_price ELSE 0 END,
						@net_price = (a.curr_price - ROUND(b.amt_disc,2)),
						@ext_net_price = (a.curr_price - ROUND(b.amt_disc,2)) * @qty
						FROM	ord_list a (NOLOCK)
						JOIN	cvo_ord_list b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.order_ext = b.order_ext
						AND		a.line_no = b.line_no
						WHERE	a.order_no = @order_no
						AND		a.order_ext = @order_ext
						AND		a.line_no = @line_no
			END
			-- v2.1 End
			RETURN
		END

		SELECT	@gross_price = b.list_price,
				@discount_price = 0,
				@discount_perc = 0,
				@net_price = b.list_price,
				@ext_net_price = (b.list_price * @qty)
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		RETURN

		-- v2.0 End
	END
	ELSE -- Non BG
	BEGIN

		SELECT	@discount_perc = discount
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no

		IF (@IsFixed = 1)
			SET @quote_net_only = 'Y'

		IF (@quote_net_only = 'N')
		BEGIN
			-- v2.3 Start
			IF (@isCredit = 'Y')
			BEGIN
				SELECT	@gross_price = b.list_price,
						@discount_price = CASE WHEN b.amt_disc = 0 THEN (b.list_price - a.curr_price) ELSE ROUND(b.amt_disc,2) END, -- v2.4
						@net_price = CASE WHEN b.amt_disc = 0 THEN a.curr_price ELSE (b.list_price - ROUND(b.amt_disc,2)) END, -- v2.4
						@ext_net_price = (CASE WHEN b.amt_disc = 0 THEN a.curr_price ELSE (b.list_price - ROUND(b.amt_disc,2)) END) * @qty -- v2.4
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
			-- v2.3 End

			SELECT	@gross_price = b.list_price,
					@discount_price = (b.list_price - (a.curr_price - ROUND(b.amt_disc,2))),
					@net_price = (a.curr_price - ROUND(b.amt_disc,2)),
					@ext_net_price = ((a.curr_price - ROUND(b.amt_disc,2)) * @qty)
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
			SELECT	@gross_price = CASE WHEN @discount_perc = 100 THEN b.list_price ELSE (a.curr_price - ROUND(b.amt_disc,2)) END,
					@discount_price = CASE WHEN @discount_perc = 100 THEN b.list_price ELSE 0 END,
					@net_price = CASE WHEN @discount_perc = 100 THEN 0 ELSE (a.curr_price - ROUND(b.amt_disc,2)) END,
					@ext_net_price = CASE WHEN @discount_perc = 100 THEN 0 ELSE ((a.curr_price - ROUND(b.amt_disc,2)) * @qty) END
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
		-- v2.0 End
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_invoice_line_prices_sp] TO [public]
GO
