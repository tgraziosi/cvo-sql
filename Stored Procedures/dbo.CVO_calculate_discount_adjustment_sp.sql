
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 23/04/2013 - Created
v1.1 CB 04/02/2016 - #1588 Add flat dollar discount to promos

retval values: 
-1	= successful, but nothing to process
-2	= successful, but no credit to apply
0	= successful and data to process
1	= invalid criteria

Testing Code:

DECLARE @ret_val INT, @message VARCHAR(1000)

EXEC dbo.CVO_calculate_discount_adjustment_sp	@customer_code = '010125', 
												@date_from	 = '2013-01-30',
												@date_to = '1 april 2013',
												@order_no_from = NULL, 
												@ext_from = NULL, 
												@order_no_to = NULL, 
												@ext_to	 = NULL, 
												@price_class= 'D',
												@ret_val = @ret_val OUTPUT,  
												@message = @message OUTPUT

SELECT @ret_val, @message
*/
CREATE PROCEDURE [dbo].[CVO_calculate_discount_adjustment_sp]	@customer_code	VARCHAR(8), 
															@date_from		DATETIME = NULL,
															@date_to		DATETIME = NULL,
															@order_no_from	INT = NULL, 
															@ext_from		INT = NULL, 
															@order_no_to	INT = NULL, 
															@ext_to			INT = NULL, 
															@price_class	VARCHAR(8),
															@ret_val		INT OUTPUT,  
															@message		VARCHAR(1000) OUTPUT 
AS
BEGIN

	DECLARE @sql				VARCHAR(2000),
			@rec_id				INT,
			@ship_to			VARCHAR(10),
			@part_no			VARCHAR(30),
			@location			VARCHAR(10),
			@qty				DECIMAL(20,8),
			@curr_key			VARCHAR(10),
			@svag_flag			CHAR(1),
			@curr_factor		DECIMAL(20,8),
			@plevel				CHAR(1),
			@std_price			DECIMAL(20,8),
			@promo_id			VARCHAR(20),
			@promo_level		VARCHAR(30),
			@promo_disc			DECIMAL(20,8),
			@cur_open			DECIMAL(20,8),
			@cur_packed			DECIMAL(20,8),
			@credit_open		DECIMAL(20,8),
			@new_open			DECIMAL(20,8),
			@new_packed			DECIMAL(20,8),
			@credit_packed		DECIMAL(20,8),
			@brand				VARCHAR(10),  
			@category			VARCHAR(10),
			@promo_price_disc	decimal(20,8) -- v1.1

	SET NOCOUNT ON

	SET @ret_val = 0

	-- Clear previous results for this SPID
	DELETE FROM CVO_discount_adjustment_results WHERE spid = @@SPID

	CREATE TABLE #order_lines(
		rec_id		INT IDENTITY(1,1) NOT NULL,
		order_no	INT NOT NULL,
		ext			INT NOT NULL,
		[status]	CHAR(1) NOT NULL,
		promo_id	VARCHAR(20) NULL,
		promo_level	VARCHAR(30) NULL,
		ship_to		VARCHAR(10) NOT NULL,
		curr_factor	DECIMAL(20,8) NOT NULL,
		oper_factor	DECIMAL(20,8) NOT NULL,
		curr_key	VARCHAR(10) NOT NULL,
		line_no		INT NOT NULL,
		location	VARCHAR(10) NOT NULL,
		part_no		VARCHAR(30) NOT NULL,
		part_type	CHAR(1) NOT NULL,
		qty			DECIMAL(20,8) NOT NULL,
		shipped		DECIMAL(20,8) NOT NULL,
		svag_flag	CHAR(1) NOT NULL,
		orig_price	DECIMAL(20,8) NOT NULL,
		discount	DECIMAL(20,8) NOT NULL,
		std_price	DECIMAL(20,8) NULL,
		promo_disc	DECIMAL(20,8) NULL,
		price_diff	DECIMAL(20,8) NULL,
		price_level	CHAR(1) NULL,
		process		SMALLINT NOT NULL)

	CREATE TABLE #order_sum(
		rec_id		INT IDENTITY(1,1) NOT NULL,
		order_no	INT NOT NULL,
		ext			INT NOT NULL,
		location	VARCHAR(10) NOT NULL,
		part_no		VARCHAR(30) NOT NULL,
		qty			DECIMAL(20,8) NOT NULL)

	CREATE TABLE #price (
		plevel		CHAR(1), 
		price		decimal(20,8), 
		next_qty	decimal(20,8),    
		next_price	decimal(20,8), 
		promo_price decimal(20,8), 
		sales_comm	decimal(20,8),    
		qloop		INT, 
		quote_level INT, 
		quote_curr	VARCHAR(10))  


	-- Build SQL to get orders
	SET @sql = ' INSERT INTO #order_lines (order_no, ext, status, promo_id, promo_level, ship_to, curr_factor, oper_factor, curr_key, line_no, location, part_no, part_type, qty, shipped, svag_flag, '
	SET @sql = @sql + ' orig_price, discount, price_level, process) '
	SET @sql = @sql + ' SELECT a.order_no, a.ext, a.status, c.promo_id, c.promo_level, a.ship_to, a.curr_factor, a.oper_factor, a.curr_key,b.line_no, b.location, b.part_no, b.part_type, b.ordered, '
	SET @sql = @sql + ' b.shipped, b.service_agreement_flag, b.curr_price, b.discount, b.price_type, '
	SET @sql = @sql + ' CASE WHEN b.price_type <> ' + '''' + 'X' + ''''+ ' AND ISNULL(d.free_frame,0) = 0  AND ISNULL(d.is_pattern,0) = 0 AND ISNULL(d.is_pop_gif,0) = 0 '
	SET @sql = @sql + ' AND b.part_type = ' + '''' + 'P' + '''' + 'THEN 1 ELSE 0 END '
	SET @sql = @sql + ' FROM dbo.orders_all a (NOLOCK) '
	SET @sql = @sql + ' INNER JOIN dbo.ord_list b (NOLOCK) '
	SET @sql = @sql + ' ON a.order_no = b.order_no '
	SET @sql = @sql + ' AND a.ext = b.order_ext '
	SET @sql = @sql + ' INNER JOIN dbo.cvo_orders_all c (NOLOCK) '
	SET @sql = @sql + ' ON a.order_no = c.order_no ' 
	SET @sql = @sql + ' AND a.ext = c.ext '
	SET @sql = @sql + ' INNER JOIN dbo.cvo_ord_list d (NOLOCK) '
	SET @sql = @sql + ' ON b.order_no = d.order_no '
	SET @sql = @sql + ' AND b.order_ext = d.order_ext '
	SET @sql = @sql + ' AND b.line_no = d.line_no '
	SET @sql = @sql + ' WHERE a.[status] <> ' + '''' + 'V' + ''' '
	SET @sql = @sql + ' AND b.[status] <> ' + '''' + 'V' + ''' '
	SET @sql = @sql + ' AND a.type = ' + '''' + 'I' + ''' '
	SET @sql = @sql + ' AND a.cust_code = ' + '''' + @customer_code + ''' '

	/*
	SET @sql = @sql + ' AND b.price_type <> ' + '''' + 'X' + ''' '
	SET @sql = @sql + ' AND ISNULL(d.free_frame,0) = 0 '
	SET @sql = @sql + ' AND b.part_type = ' + '''' + 'P' + ''' '
	*/

	-- Date from
	IF @date_from IS NOT NULL
	BEGIN
		SET @sql = @sql + ' AND a.date_entered >= ' + '''' + CONVERT(VARCHAR(16),@date_from, 120) + ''''
	END

	-- Date to
	IF @date_to IS NOT NULL
	BEGIN
		SET @sql = @sql + ' AND a.date_entered <= ' + '''' + CONVERT(VARCHAR(16),@date_to, 120) + ''''
	END
	
	-- Order from
	IF @order_no_from IS NOT NULL
	BEGIN
		SET @sql = @sql + ' AND ((a.order_no > ' + CAST(@order_no_from AS VARCHAR(10)) + ') OR (a.order_no = ' + CAST(@order_no_from AS VARCHAR(10)) + ' AND a.ext >= ' + CAST(ISNULL(@ext_from,0) AS VARCHAR(3)) + '))'
		--SET @sql = @sql + ' AND (a.order_no >= ' + CAST(@order_no_from AS VARCHAR(10)) + ' AND a.ext >= ' + CAST(ISNULL(@ext_from,0) AS VARCHAR(3)) + ')'
	END	

	-- Order to
	IF @order_no_to IS NOT NULL
	BEGIN
		SET @sql = @sql + ' AND ((a.order_no < ' + CAST(@order_no_to AS VARCHAR(10)) + ') OR (a.order_no = ' + CAST(@order_no_to AS VARCHAR(10)) + ' AND a.ext <= ' + CAST(ISNULL(@ext_to,0) AS VARCHAR(3)) + '))'
		--SET @sql = @sql + ' AND (a.order_no <= ' + CAST(@order_no_to AS VARCHAR(10)) + ' AND a.ext <= ' + CAST(ISNULL(@ext_to,0) AS VARCHAR(3)) + ')'
	END

	EXEC (@sql)
	
	IF NOT EXISTS (SELECT 1 FROM #order_lines)
	BEGIN
		SET @ret_val = -1
		RETURN
	END

	INSERT INTO #order_sum(
		order_no,
		ext,
		location,
		part_no,
		qty)
	SELECT
		order_no,
		ext,
		location,
		part_no,
		SUM(qty)
	FROM
		#order_lines
	GROUP BY
		order_no,
		ext,
		location,
		part_no


	-- Calculate std price for each line
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		
		SELECT TOP 1
			@rec_id = rec_id
		FROM
			#order_lines
		WHERE
			rec_id > @rec_id
			AND process = 1
		ORDER BY
			rec_id
			
		IF @@ROWCOUNT = 0
			BREAK

		-- Get details
		SELECT 
			@ship_to = a.ship_to,
			@part_no = a.part_no,
			@location = a.location,
			@qty = b.qty,
			@curr_key = a.curr_key,
			@curr_factor = a.curr_factor,
			@svag_flag = a.svag_flag,
			@promo_id = a.promo_id,
			@promo_level = a.promo_level,
			@category = c.type_code,   
			@brand = c.category   
		FROM
			#order_lines a
		INNER JOIN
			#order_sum b
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext 
			AND a.location = b.location
			AND a.part_no = b.part_no
		INNER JOIN
			dbo.inv_master c (NOLOCK)
		ON
			a.part_no = c.part_no
		WHERE
			a.rec_id = @rec_id


		-- Create temp table to pass new price class into fs_get_price
		CREATE TABLE #cvo_discount_adjustment_pass_price_class(
			price_class	VARCHAR(8))

		INSERT INTO #cvo_discount_adjustment_pass_price_class VALUES(@price_class)


		INSERT INTO 
			#price 
		EXEC dbo.fs_get_price	@cust =	@customer_code,  
								@shipto = @ship_to,  
								@clevel = '1',  
								@pn = @part_no,  
								@loc = @location,  
								@plevel = '1',  
								@qty = @qty,  
								@pct = 0,  
								@curr_key = @curr_key,  
								@curr_factor = @curr_factor,  
								@svc_agr = @svag_flag    
    
		SELECT  
			@std_price = price,  
			@plevel = plevel  
		FROM  
			#price   

		DROP TABLE #cvo_discount_adjustment_pass_price_class

		-- Promo pricing
		SET @promo_disc = 0
		SELECT TOP 1  
			@promo_disc = ISNULL(discount_per,0),
			@promo_price_disc = ISNULL(discount_price_per,0) -- v1.1
		FROM  
			dbo.cvo_line_discounts (NOLOCK)  
		WHERE  
			promo_id = @promo_id  
			AND promo_level = @promo_level  
			AND ((ISNULL(brand,'') = '') OR (ISNULL(brand,'') <> @brand))  
			AND ((ISNULL(category,'') = '') OR (ISNULL(category,'') <> @category))  
			AND ISNULL(price_override,'N') = 'N'
			AND ISNULL(list,'N') = 'N'
		ORDER BY  
			line_no  

		-- v1.1 Start
		IF (@promo_price_disc > 0)
		BEGIN
			IF (@promo_price_disc >= @std_price)
			BEGIN
				SET @promo_disc = 100
			END
			ELSE
			BEGIN
				SET @promo_disc = 100 - (((@std_price - @promo_price_disc) / @std_price) * 100)
			END
		END
		-- v1.1 End

		UPDATE
			#order_lines
		SET
			std_price = @std_price,
			price_level = CASE orig_price WHEN @std_price THEN price_level ELSE @plevel END,
			promo_disc = ISNULL(@promo_disc,0)
		WHERE
			rec_id = @rec_id

		DELETE FROM #price
	END	

	-- Remove any packed orders which already exist in the audit table
	DELETE 
		a
	FROM 
		#order_lines a
	INNER JOIN
		dbo.CVO_discount_adjustment_audit b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext
		AND a.line_no = b.line_no
		AND a.[status] >= 'R'
		AND b.[status] >= 'R'
		

	-- Is there anything to process?
	IF NOT EXISTS (SELECT 1 FROM #order_lines WHERE process = 1)
	BEGIN
		SET @ret_val = -1
		RETURN
	END

	-- Calculate open figures
	SELECT 
		@cur_open = SUM(CASE ISNULL(discount,0) WHEN 0 THEN qty * orig_price ELSE qty * (orig_price - ((orig_price *(discount/100)))) END),
		@new_open = SUM(CASE ISNULL(process,0) 
							WHEN 0 THEN (CASE ISNULL(discount,0) WHEN 0 THEN qty * orig_price ELSE qty * (orig_price - ((orig_price * (discount/100)))) END)
							WHEN 1 THEN (CASE ISNULL(promo_disc,0) WHEN 0 THEN qty * std_price ELSE qty * (std_price - ((std_price * (promo_disc/100)))) END)							
						END )
	FROM
		#order_lines
	WHERE
		[status] < 'R'

	SET @credit_open = @cur_open - @new_open

	-- Calculate packed figures
	SELECT 
		@cur_packed = SUM(CASE ISNULL(discount,0) WHEN 0 THEN shipped * orig_price ELSE shipped * (orig_price - ((orig_price * (discount/100)))) END),
		@new_packed = SUM(CASE ISNULL(process,0) 
							WHEN 0 THEN (CASE ISNULL(discount,0) WHEN 0 THEN shipped * orig_price ELSE shipped * (orig_price - ((orig_price * (discount/100)))) END)
							WHEN 1 THEN (CASE ISNULL(promo_disc,0) WHEN 0 THEN shipped * std_price ELSE shipped * (std_price - ((std_price * (promo_disc/100)))) END)
						END )
	FROM
		#order_lines
	WHERE
		[status] >= 'R'

	SET @credit_packed = @cur_packed - @new_packed

	-- Calculate price difference
	UPDATE
		#order_lines
	SET
		price_diff = (CASE ISNULL(discount,0) 
						WHEN 0 THEN (CASE WHEN [status] >= 'R' THEN shipped ELSE qty END) * orig_price 
						ELSE (CASE WHEN [status] >= 'R' THEN shipped ELSE qty END) * (orig_price - ((orig_price * (discount/100)))) 
					  END) 
					- (CASE ISNULL(promo_disc,0) 
						WHEN 0 THEN (CASE WHEN [status] >= 'R' THEN shipped ELSE qty END) * std_price 
						ELSE (CASE WHEN [status] >= 'R' THEN shipped ELSE qty END) * (std_price - ((std_price * (promo_disc/100)))) 
					  END)
	WHERE
		process = 1

	-- Unmark are lines where the difference is 0
	UPDATE
		#order_lines
	SET
		process = 0
	WHERE
		process = 1
		AND ISNULL(price_diff,0) = 0

	-- Order Totals need to be based on the actual order totals - get these
	CREATE TABLE #orders (
		order_no INT,
		ext INT,
		order_total DECIMAL(20,8))

	-- Open orders
	INSERT INTO #orders(
		order_no,
		ext)
	SELECT DISTINCT
		order_no,
		ext
	FROM
		#order_lines
	WHERE
		[status] < 'R'
	
	UPDATE
		a
	SET
		order_total = b.total_amt_order - ISNULL(b.tot_ord_disc,0)
	FROM
		#orders a
	INNER JOIN
		dbo.orders_all b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext


	SELECT @cur_open = SUM(ISNULL(order_total,0)) FROM #orders
	SELECT @new_open = @cur_open - @credit_open

	DELETE FROM #orders

	-- Packed orders
	INSERT INTO #orders(
		order_no,
		ext)
	SELECT DISTINCT
		order_no,
		ext
	FROM
		#order_lines
	WHERE
		[status] >= 'R'
	
	UPDATE
		a
	SET
		order_total = b.gross_sales - ISNULL(b.total_discount,0)
	FROM
		#orders a
	INNER JOIN
		dbo.orders_all b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext

	SELECT @cur_packed = SUM(ISNULL(order_total,0)) FROM #orders
	SELECT @new_packed = @cur_packed - @credit_packed
	

	-- Output message
	SELECT @message = 'Open Orders:' + CHAR(10) 
	SELECT @message = @message + 'Current Order Total: $' + CAST(CAST(ISNULL(@cur_open,0) AS MONEY) AS VARCHAR(20)) + CHAR(10)
	SELECT @message = @message + 'New Order Total: $' + CAST(CAST(ISNULL(@new_open,0) AS MONEY) AS VARCHAR(20)) + CHAR(10) 
	SELECT @message = @message + 'Credit Amount: $' + CAST(CAST(ISNULL(@credit_open,0) AS MONEY) AS VARCHAR(20)) + CHAR(10) + CHAR(13)
	SELECT @message = @message + 'Packed Orders:' + CHAR(10) 
	SELECT @message = @message + 'Current Order Total: $' + CAST(CAST(ISNULL(@cur_packed,0) AS MONEY) AS VARCHAR(20)) + CHAR(10) 
	SELECT @message = @message + 'New Order Total: $' + CAST(CAST(ISNULL(@new_packed,0) AS MONEY) AS VARCHAR(20)) + CHAR(10) 
	SELECT @message = @message + 'Credit Amount: $' + CAST(CAST(ISNULL(@credit_packed,0) AS MONEY) AS VARCHAR(20)) 

	IF ISNULL(@credit_packed,0) <= 0 AND ISNULL(@credit_open,0) = 0
	BEGIN
		SET @ret_val = -2
		RETURN
	END
	
	-- Store results in table
	IF @ret_val = 0
	BEGIN
		INSERT INTO CVO_discount_adjustment_results(
			spid,
			order_no, 
			ext, 
			[status], 
			promo_id, 
			promo_level, 
			ship_to, 
			curr_factor, 
			oper_factor, 
			curr_key, 
			line_no, 
			location, 
			part_no, 
			part_type, 
			qty, 
			svag_flag, 
			orig_price,
			discount, 
			std_price,
			promo_disc,
			price_level, 
			price_diff,
			process,
			date_from,		
			date_to,
			price_class,
			cust_code)
		SELECT
			@@SPID,
			order_no, 
			ext, 
			[status], 
			promo_id, 
			promo_level, 
			ship_to, 
			curr_factor, 
			oper_factor, 
			curr_key, 
			line_no, 
			location, 
			part_no, 
			part_type, 
			CASE WHEN [status] >= 'R' THEN shipped ELSE qty END, 
			svag_flag, 
			orig_price,
			discount, 
			ISNULL(std_price,0),
			promo_disc,
			price_level, 
			price_diff,
			process,
			@date_from,		
			@date_to,
			@price_class,
			@customer_code
		FROM
			#order_lines
		ORDER BY
			rec_id
	END							

END
GO

GRANT EXECUTE ON  [dbo].[CVO_calculate_discount_adjustment_sp] TO [public]
GO
