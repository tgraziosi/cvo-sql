SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 11/10/2012 - Gets price for a part on a credit return based on customer settings
-- v1.1 CT 11/12/2012 - Look in historic orders table too
-- v1.2 CT 17/12/2012 - Return list price
-- v1.3 CT 17/12/2012 - Ignore order lines where shipped = 0
-- v1.4	CT 07/02/2013 - When getting price from ord_list, use curr_price instead of price field
-- v1.5	CT 28/02/2013 - Ignore order lines where price = 0
-- v1.6	CT 14/03/2013 - Promo Ignore For Credit Pricing logic
-- v1.7 CT 15/03/2013 - Don't delete order lines where price = 0 that are for an ignore promo
-- v1.8	CT 15/05/2013 - Issue #1267 - For highest and lowest price, add secondary sort of time_entered
-- v1.9 CT 15/05/2013 - Issue #1267 - For historic orders, get list price from cvo_ord_list_hist.cost 
-- v2.0 CB 10/06/2013 - Issue #1112 - Additional affiliated customer
-- v2.1 CB 16/07/2013 - Issue #927 - Buying Group Switching
-- EXEC CVO_credit_for_returns_price_sp '035672','BCALBBLA5115'

CREATE PROC [dbo].[CVO_credit_for_returns_price_sp] (@customer_code VARCHAR(8),
												 @part_no VARCHAR(30))
AS
BEGIN
	DECLARE @time_frame INT,
			@start_date DATETIME,
			@credit_for_returns SMALLINT,
			@price DECIMAL(20,8),
			-- START v1.2
			@order_no INT,
			@order_ext INT,
			@line_no INT,
			@list_price DECIMAL(20,8)
			-- END v1.2

	-- Create table to hold customer codes
	CREATE TABLE #customers (
		customer_code VARCHAR(8),
		cust_type CHAR(1))

	-- START v1.1
	-- Create table to hold prices
	CREATE TABLE #prices (
		price DECIMAL(20,8),
		time_entered DATETIME,
		-- START v1.2
		order_no INT,
		order_ext INT,
		line_no INT,
		ignore SMALLINT) -- v1.6
		-- END v1.2
	-- END v1.1

	-- Load this customer
	INSERT 
		#customers 
	SELECT 
		@customer_code,
		'C'

	-- Load affiliated customer
	INSERT 
		#customers
	SELECT
		affiliated_cust_code,
		'A'
	FROM
		dbo.armaster_all (NOLOCK)
	WHERE
		address_type = 0
		AND customer_code = @customer_code

	-- v2.0 Start
	-- Load affiliated customer from cvo_affiliated_customers table
	INSERT 
		#customers
	SELECT
		affiliated_code,
		'A'
	FROM
		dbo.cvo_affiliated_customers (NOLOCK)
	WHERE
		customer_code = @customer_code


	-- v2.0 End

	-- Load parent (buying group)
	INSERT 
		#customers 
	SELECT 
		dbo.f_cvo_get_buying_group(@customer_code,GETDATE()), -- v2.1
-- v2.1		dbo.f_get_buying_group(@customer_code),
		'P'

	-- Remove NULLs
	DELETE FROM #customers WHERE ISNULL(customer_code,'') = ''

	-- Get customer's credit for returns setting
	SELECT
		@credit_for_returns = credit_for_returns
	FROM
		dbo.cvo_armaster_all (NOLOCK)
	WHERE
		address_type = 0
		AND customer_code = @customer_code

	-- If not set use default
	IF ISNULL(@credit_for_returns,3) > 2
	BEGIN
		SET @credit_for_returns = 0
	END
	 
	-- Get timeframe from config
	SELECT @time_frame = CAST(value_str AS INT) FROM config WHERE flag = 'CR_PRICE_TIME_PERIOD'
	SELECT @time_frame = @time_frame * -1

	-- Set start date for search
	SET @start_date = DATEADD(d,@time_frame,GETDATE())

	-- START v1.1
	-- Load order price details into table
	INSERT #prices(
		price,
		time_entered,
		-- START v1.2
		order_no,
		order_ext,
		line_no,
		ignore) -- v1.6
		-- END v1.2
	SELECT 
		-- START v1.4
		CASE ISNULL(a.discount,0) WHEN 0 THEN a.curr_price ELSE ROUND((a.curr_price - (a.curr_price * (a.discount/100))),2) END,
		--CASE ISNULL(a.discount,0) WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END,
		-- END v1.4
		a.time_entered,
		-- START v1.2
		a.order_no,
		a.order_ext,
		a.line_no,
		-- END v1.2 
		ISNULL(e.ignore_for_credit_pricing,0) -- v1.6
	FROM
		dbo.ord_list a (NOLOCK)
	INNER JOIN
		dbo.orders_all b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.ext
	INNER JOIN
		#customers c (NOLOCK)
	ON
		b.cust_code = c.customer_code
	-- START v1.6
	INNER JOIN
		dbo.cvo_orders_all d (NOLOCK)
	ON
		b.order_no = d.order_no
		AND b.ext = d.ext
	LEFT JOIN
		dbo.cvo_promotions e (NOLOCK)
	ON
		d.promo_id = e.promo_id
		AND d.promo_level = e.promo_level
	-- END v1.6
	WHERE
		b.status <> 'V'
		AND b.type = 'I'
		AND a.time_entered >= @start_date
		AND a.part_no = @part_no
		AND a.shipped > 0 -- v1.3

	-- Load historic order price details into table
	INSERT #prices(
		price,
		time_entered,
		-- START v1.2
		order_no,
		order_ext,
		line_no,
		ignore) -- v1.6
		-- END v1.2
	SELECT 
		CASE ISNULL(a.discount,0) WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END,
		a.time_entered,
		-- START v1.2
		a.order_no,
		a.order_ext,
		a.line_no,
		-- END v1.2  
		ISNULL(e.ignore_for_credit_pricing,0) -- v1.6
	FROM
		dbo.cvo_ord_list_hist a (NOLOCK)
	INNER JOIN
		dbo.cvo_orders_all_hist b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.ext
	INNER JOIN
		#customers c (NOLOCK)
	ON
		b.cust_code = c.customer_code
	-- START v1.6
	LEFT JOIN
		dbo.cvo_orders_all d (NOLOCK)
	ON
		b.order_no = d.order_no
		AND b.ext = d.ext
	LEFT JOIN
		dbo.cvo_promotions e (NOLOCK)
	ON
		d.promo_id = e.promo_id
		AND d.promo_level = e.promo_level
	-- END v1.6
	WHERE
		b.status <> 'V'
		AND b.type = 'I'
		AND a.time_entered >= @start_date
		AND a.part_no = @part_no
		AND a.shipped > 0 -- v1.3
	-- END v1.1

	-- START v1.5
	DELETE FROM
		#prices
	WHERE
		price = 0
		AND ignore = 0 -- v1.7
	-- END v1.5

	SET @price = NULL

	-- Get price
	IF @credit_for_returns = 0 -- lowest price
	BEGIN
		-- START v1.1
		SELECT TOP 1
			@price = price,
			-- START v1.2
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no
			-- END v1.2
		FROM
			#prices
		-- START v1.6
		WHERE
			ignore = 0
		-- END v1.6
		ORDER BY
			price ASC,
			time_entered ASC -- v1.8

		/*
		SELECT TOP 1
			@price = CASE a.discount WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END
		FROM
			dbo.ord_list a (NOLOCK)
		INNER JOIN
			dbo.orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.ext
		INNER JOIN
			#customers c (NOLOCK)
		ON
			b.cust_code = c.customer_code
		WHERE
			b.status <> 'V'
			AND b.type = 'I'
			AND a.time_entered >= @start_date
			AND a.part_no = @part_no
		ORDER BY
			CASE a.discount WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END ASC
		*/
		-- END v1.1
	END

	IF @credit_for_returns = 1 -- highest price
	BEGIN
		-- START v1.1
		SELECT TOP 1
			@price = price,
			-- START v1.2
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no
			-- END v1.2
		FROM
			#prices
		-- START v1.6
		WHERE
			ignore = 0
		-- END v1.6
		ORDER BY
			price DESC,
			time_entered ASC -- v1.8
		/*
		
		SELECT TOP 1
			@price = CASE a.discount WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END
		FROM
			dbo.ord_list a (NOLOCK)
		INNER JOIN
			dbo.orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.ext
		INNER JOIN
			#customers c (NOLOCK)
		ON
			b.cust_code = c.customer_code
		WHERE
			b.status <> 'V'
			AND b.type = 'I'
			AND a.time_entered >= @start_date
			AND a.part_no = @part_no
		ORDER BY
			CASE a.discount WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END DESC
		*/
		-- END v1.1
	END

	IF @credit_for_returns = 2 -- most recent price
	BEGIN
		-- START v1.1
		SELECT TOP 1
			@price = price,
			-- START v1.2
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no
			-- END v1.2
		FROM
			#prices
		-- START v1.6
		WHERE
			ignore = 0
		-- END v1.6
		ORDER BY
			time_entered DESC
		/*
		SELECT TOP 1
			@price = CASE a.discount WHEN 0 THEN a.price ELSE ROUND((a.price - (a.price * (a.discount/100))),2) END
		FROM
			dbo.ord_list a (NOLOCK)
		INNER JOIN
			dbo.orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.ext
		INNER JOIN
			#customers c (NOLOCK)
		ON
			b.cust_code = c.customer_code
		WHERE
			b.status <> 'V'
			AND b.type = 'I'
			AND a.time_entered >= @start_date
			AND a.part_no = @part_no
		ORDER BY
			a.time_entered DESC
		*/
		-- END v1.1
	END

	-- START v1.6
	SET @list_price = NULL

	-- If we haven't found a price, check if there are any ignored orders
	IF @price IS NULL
	BEGIN
		IF EXISTS (SELECT 1 FROM #prices WHERE ignore <> 0)		
		BEGIN
			-- Set price to 0 to signify std pricing required
			SET @price = 0
			SET @list_price = 0
		END
	END
	ELSE
	BEGIN
		-- START v1.9
		-- Check if this is a current or historic order
		IF EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)
		BEGIN
			-- Current
			-- START v1.2 - get list price
			SELECT
				@list_price = list_price
			FROM
				dbo.cvo_ord_list (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @order_ext
				AND line_no = @line_no
			-- END v1.2
		END
		ELSE
		BEGIN
			-- Historic
			SELECT
				@list_price = cost
			FROM
				dbo.cvo_ord_list_hist (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @order_ext
				AND line_no = @line_no	
		END
		-- END v1.9
	END
	-- END v1.6

	DROP TABLE #customers
	DROP TABLE #prices -- v1.1

	SELECT @price, @list_price -- v1.2
END
GO
GRANT EXECUTE ON  [dbo].[CVO_credit_for_returns_price_sp] TO [public]
GO
