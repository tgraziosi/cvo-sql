SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 31/05/11 - 68668-U52685ENT - When failing qualification, return the reason the customer failed
-- v1.2 CT 13/07/11 - Min/Max sales must take into account brand/category
-- v1.3	CT 10/08/11 - Include historic order data (cvo_orders_all_hist and cvo_ord_list_hist)
-- v1.4	CT 24/08/11	- cvo_ord_list_hist.order_no and cvo_orders_all_hist.order_no are now INT (was VARCHAR)	
-- v2.0 TM 09/09/11 - pull promo id and level from the history data
-- v2.1 CB 19/01/12 - Not dealing with credit values correctly
-- v2.2 CB 31/01/12	- Fix issue when multiple promo lines with no condition set
-- v2.4 CB 29/02/12 - Default min sales to -9999999
-- v2.5 CB 30/03/12 - Fix issue with return %
-- v2.6 CB 13/09/12 - Fix issue with credit values being reversed now fix has been applied to underlying view 
-- v2.7 CT 29/10/12 - Return 1 if promo qualifies, 0 if not
-- v2.8	CT 29/10/12 - Add frequency logic	
-- v2.9 CT 06/02/13 - CVO-CF-37 - Additional qualification criteria 

-- Copied from CVO_verify_customer_quali_sp, v1.1 to v2.9 are for the original SP.  This SP starts at V3.0
-- v3.0 CT 07/02/13 - Created
-- v3.1	CT 13/02/13 - Change to how gender is stored against a promo
-- v3.2 CT 13/02/13 - Additional field of max number of pieces
-- v3.3 CT 13/05/13 - Issue #1266 - Promo frequency - only check orders created between promo start and end date
-- v3.4 CT 13/08/13 - Issue #1353 - When calculating frequency, only include orders with an extension of 0
-- v3.5 CT 12/02/14 - Issue #1426 - Check frequency type
-- v3.6 CT 14/10/14 - Issue #1499 - Promo level buy in
-- v3.7 CB 23/10/15 - #1541 - Promo rolling periods
-- v3.8 CB 19/04/2016 - #1584 - Add min, max and number of pieces for stock order. Add min and for RX reorders.
-- v3.9 CB 11/07/2016 - Only return fail message if actually failed
-- v4.0	CB	08/12/2017 - #1650 - Promo sub brand

-- EXEC [CVO_verify_customer_shipto_quali_sp] 'CB','1','045911', '0001', 1418426, 0

CREATE PROCEDURE [dbo].[CVO_verify_customer_shipto_quali_sp]	@promo_id	VARCHAR(20), @promo_level VARCHAR(30), @customer VARCHAR(30), 
																@ship_to VARCHAR(10),@order_no INT = 0, @ext INT = 0, @sub_check SMALLINT = 0 -- v2.9 (add ship_to parameter)
AS
BEGIN
		DECLARE	@id					INT,
				@min_sales			DECIMAL(20, 8),
				@max_sales			DECIMAL(20, 8),
				@start_date			DATETIME,
				@end_date			DATETIME,
				@achived			INT,
				@so_ext				VARCHAR(40),
				@rows_found			VARCHAR(3),
				@cond1				VARCHAR(1),
				@cond2				VARCHAR(1),
				@brand_exclude		VARCHAR(1),
				@category_exclude	VARCHAR(1),
				@brand				VARCHAR(30),
				@category			VARCHAR(30),	
				@max				INT,
				@counter			INT,
				@rows_rx			INT,
				@returns			INT,
				@brand_found		INT,
				@category_found		INT,
				@condition			VARCHAR(MAX),
				@past_promo_id		VARCHAR(30),
				@past_promo_level	VARCHAR(30),
				@min_rx_per			DECIMAL(20, 8),
				@max_rx_per			DECIMAL(20, 8),
				@return_per			DECIMAL(20, 8),
				@per_rx_order		DECIMAL(20, 8),
				@per_return			DECIMAL(20, 8),
				@fail_reason		varchar(200),	-- v1.1
				@order_sales		DECIMAL (20,8),	-- v1.2
				@historic_sales		DECIMAL (20,8),
				@frequency			INT,		-- v2.8
				@order_count		INT,		-- v2.8
				@frequency_fail		SMALLINT,	-- v2.8
				-- START v2.9
				-- START v3.1
				--@gender				VARCHAR(15),	
				@gender_check		SMALLINT,
				-- END v3.1
				@no_of_pieces		DECIMAL(20,8),	
				@order_type			SMALLINT,		
				@attribute			SMALLINT,		
				@order_pieces		DECIMAL (20,8),	
				@line_no			INT,	
				-- END v2.9
				@max_no_of_pieces	DECIMAL(20,8), -- v3.2
				-- START v3.3
				@promo_start_date	DATETIME,
				@promo_end_date		DATETIME,
				-- END v3.3
				-- START v3.5
				@frequency_type		CHAR(1), 
				@date_entered		DATETIME,
				-- END v3.5
				@pp_not_purchased	SMALLINT, -- v3.6
				@rolling_period		smallint, -- v3.7
				@min_stock_orders	smallint, -- v3.8
				@max_stock_orders	smallint, -- v3.8
				@stock_orders_pieces smallint, -- v3.8
				@min_rx_orders		smallint, -- v3.8
				@max_rx_orders		smallint, -- v3.8
				@order_cnt			int, -- v3.8
				@att_count			int, -- v4.0
				@att_sales			decimal(20,8), -- v4.0
				@att_order_cnt		int -- v4.0

		SET @fail_reason = '' -- v1.1
		SET @frequency_fail = 0

		CREATE TABLE #cvo_customer_qualifications(
			id					INT IDENTITY(1,1),
			line_no				INT,
			brand				VARCHAR(30),
			brand_exclude		VARCHAR(1),
			category			VARCHAR(30),
			category_exclude	VARCHAR(1),
			min_sales			DECIMAL(20, 8),
			max_sales			DECIMAL(20, 8),
			start_date			DATETIME,
			end_date			DATETIME,
			past_promo_id		VARCHAR(30),
			past_promo_level	VARCHAR(30),
			min_rx_per			DECIMAL(20, 8),
			max_rx_per			DECIMAL(20, 8),
			return_per			DECIMAL(20, 8),
			and_				VARCHAR(1),
			or_					VARCHAR(1),
			rows_found			VARCHAR(3),
			-- START v2.9
			gender				VARCHAR(15),
			no_of_pieces		DECIMAL (20,8),
			order_type			SMALLINT,
			attribute			SMALLINT,
			-- END v2.9
			gender_check		SMALLINT,		-- v3.1
			max_no_of_pieces	DECIMAL(20,8),	-- v3.2
			pp_not_purchased	SMALLINT,		-- v3.6
			rolling_period		smallint, -- v3.7
			min_stock_orders	smallint, -- v3.8
			max_stock_orders	smallint, -- v3.8
			stock_orders_pieces smallint, -- v3.8
			min_rx_orders		smallint, -- v3.8
			max_rx_orders		smallint -- v3.8
		)

		-- START v2.9
		CREATE TABLE #cvo_customer_qualifications_order_type(
			line_no				INT,
			order_type			VARCHAR(10)
		)

		CREATE TABLE #cvo_customer_qualifications_attribute(
			line_no				INT,
			attribute			VARCHAR(10)
		)
		-- END v2.9

		-- START v3.1
		CREATE TABLE #cvo_customer_qualifications_gender(
			line_no				INT,
			gender				VARCHAR(15)
		)
		-- END v3.1

		CREATE TABLE #orders(
			id					INT IDENTITY(1,1),
			order_no			INT,
			ext					INT,
			total_amt_order		DECIMAL(20, 8),
			user_category		VARCHAR(10) NULL,
			promo_id			VARCHAR(20) NULL,
			promo_level			VARCHAR(30)	NULL,
			historic			SMALLINT	NULL,	-- v1.3
			order_no_text		VARCHAR(20)	NULL,	-- v1.3
			type				CHAR(1) NULL -- v2.1
		)

		CREATE TABLE #ord_list (
			part_no		VARCHAR(30),
			brand		VARCHAR(30),
			category	VARCHAR(30)
		)

		-- v3.8 Start
		CREATE TABLE #count_orders (
			order_no	int,
			order_ext	int,
			rec_count	int)
		-- v3.8 End

		-- v4.0 Start
		CREATE TABLE #att_count_orders (
			order_no	int,
			order_ext	int,
			rec_count	int)
		-- v4.0 End

		-- START v2.8
		SELECT 
			@frequency = ISNULL(frequency,0),
			-- START v3.7
			@frequency_type = ISNULL(frequency_type,'A')
			/*
			-- START v3.3
			@promo_start_date = promo_start_date,
			@promo_end_date = promo_end_date,
			-- END v3.3
			*/
			-- END v3.7
		FROM
			dbo.cvo_promotions (NOLOCK)
		WHERE
			promo_id = @promo_id
			AND promo_level = @promo_level

		-- START v3.7
		/*
		-- v3.3 - Roll on end date
		SET @promo_end_date = DATEADD(d,1,@promo_end_date)
		*/
		-- END v3.7

		IF @frequency > 0 
		BEGIN
			-- START v3.7
			-- Get order creation date if order number has been passed
			IF @order_no = 0 OR @ext = -1
			BEGIN
				SET @date_entered = GETDATE()
			END
			ELSE
			BEGIN
				SELECT
					@date_entered = date_entered 
				FROM
					dbo.orders_all (NOLOCK)
				WHERE
					order_no = @order_no 
					AND ext = @ext
			END

			SET @date_entered = ISNULL(@date_entered,GETDATE())

			-- Get start and end date
			EXEC cvo_get_promo_frequency_dates_sp @date_entered, @frequency_type, @promo_start_date OUTPUT,	@promo_end_date OUTPUT
			-- END v3.7

			-- Get number of orders for this customer/ship to and promo
			SELECT 
				@order_count = COUNT(a.order_no) 
			FROM 
				dbo.orders_all a (NOLOCK)
			INNER JOIN
				dbo.cvo_orders_all b (NOLOCK)
			ON
				a.order_no = b.order_no
				AND a.ext = b.ext
			WHERE
				a.cust_code = @customer
				AND a.ship_to = @ship_to
				AND a.[type] = 'I'
				AND NOT (a.order_no = @order_no AND a.ext = @ext)
				AND b.promo_id = @promo_id
				AND b.promo_level = @promo_level
				AND a.[status] <> 'V'
				-- START v3.3
				AND a.date_entered > @promo_start_date
				AND a.date_entered < @promo_end_date
				-- END v3.3
				AND a.ext = 0 -- v3.4

			IF ISNULL(@order_count,0) >= @frequency
			BEGIN
				SET @frequency_fail = 1
				IF @sub_check = 0
				BEGIN
					SELECT 0 as code, 'Customer/Ship To does not qualify for promotion - Frequency.' as reason 
					RETURN	
				END
				ELSE
				BEGIN
					RETURN 0
				END
			END

		END
		-- END v2.8

		INSERT INTO #cvo_customer_qualifications(
				line_no,		brand,				brand_exclude,
				category,		category_exclude,	min_sales,
				max_sales,		start_date,			end_date,
				past_promo_id,	past_promo_level,	min_rx_per,			
				max_rx_per,		return_per,			and_,				
				or_, 			rows_found,
				-- START v2.9
				gender,			no_of_pieces,		order_type,
				attribute,
				-- END v2.9
				gender_check,		-- v3.1
				max_no_of_pieces,	-- v3.2
				pp_not_purchased,	-- v3.6
				rolling_period, -- v3.7
				min_stock_orders, max_stock_orders, stock_orders_pieces, min_rx_orders, max_rx_orders -- v3.8
		)
		SELECT	line_no,		brand,				brand_exclude,
				category,		category_exclude,	min_sales,
				max_sales,		start_date,			end_date,
				past_promo_id,	past_promo_level,	min_rx_per,			
				max_rx_per,		return_per,			and_,				
				or_,			'0=1',
				-- START v2.9
				gender,			no_of_pieces,	order_type,
				attribute,
				-- END v2.9
				gender_check,		-- v3.1
				max_no_of_pieces,	-- v3.2
				pp_not_purchased,	-- v3.6
				rolling_period, -- v3.7
				min_stock_orders, max_stock_orders, stock_orders_pieces, min_rx_orders, max_rx_orders -- v3.8
		FROM	CVO_customer_qualifications (NOLOCK)
		WHERE	promo_id = @promo_id AND
				promo_level = @promo_level
		ORDER BY line_no
		
		--	If there are no Customer Qualifications then set to PASS and exit
		IF (SELECT COUNT(*) FROM CVO_customer_qualifications (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level) = 0
		BEGIN
			-- START v2.8
			IF @frequency_fail = 0
			BEGIN
				-- START v2.7 
				IF @sub_check = 0
				BEGIN
					SELECT 1
					RETURN	
				END
				ELSE
				BEGIN
					RETURN 1
				END
				-- END v2.7
			END
			-- END v2.8
		END

		SELECT @so_ext = CAST(@order_no AS VARCHAR(20)) + '-' + CAST(@ext AS VARCHAR(20))

		SELECT	@id = MIN(id)
		FROM	#cvo_customer_qualifications
		
		WHILE (@id IS NOT NULL)
		BEGIN
			SELECT	@min_sales = IsNull(min_sales,-99999999), @max_sales = IsNull(max_sales,999999999), -- v2.4
					@start_date = [start_date], @end_date = end_date,
					@past_promo_id = past_promo_id, @past_promo_level = past_promo_level, @min_rx_per = IsNull(min_rx_per,0),
					@max_rx_per = IsNull(max_rx_per,999999999), @return_per = IsNull(return_per,0), @brand = brand, @category = category,
					@brand_exclude = brand_exclude, @category_exclude = category_exclude,
					-- START v2.9
					-- START v3.1
					--@gender = gender, @no_of_pieces = no_of_pieces,	@order_type = order_type, @attribute = attribute, @line_no = line_no
					@gender_check = gender_check, @no_of_pieces = no_of_pieces,	@order_type = order_type, @attribute = attribute, @line_no = line_no,
					-- END v3.1
					-- END v2.9
					@max_no_of_pieces = max_no_of_pieces, -- v3.2
					@pp_not_purchased = pp_not_purchased,  -- v3.6
					@rolling_period = rolling_period, -- v3.7
					@min_stock_orders = min_stock_orders, @max_stock_orders = max_stock_orders, -- v3.8
					@stock_orders_pieces = stock_orders_pieces, @min_rx_orders = min_rx_orders, @max_rx_orders = max_rx_orders -- v3.8
			FROM 	#cvo_customer_qualifications
			WHERE	id = @id

			SELECT @achived = 0

			-- v3.7 Start
			IF (ISNULL(@rolling_period,0) > 0)
			BEGIN
				SET @end_date = GETDATE()
				SET @start_date = DATEADD(MONTH,(@rolling_period * -1),@end_date)
			END
			-- v3.7 End

			-- START v1.3
			-- Load current orders
			INSERT INTO #orders ( order_no, ext, total_amt_order, user_category, promo_id, promo_level, historic, order_no_text, type )
			SELECT	o.order_no, o.ext, CASE WHEN o.type = 'C' THEN (o.total_amt_order * -1) ELSE o.total_amt_order END, -- v2.1
					o.user_category, IsNull(co.promo_id,''), IsNull(co.promo_level,''), 0, CAST(o.order_no AS VARCHAR(20)), o.type	--v2.0
			FROM	orders_all o (NOLOCK) LEFT JOIN CVO_orders_all co (NOLOCK) ON o.order_no = co.order_no AND o.ext = co.ext
			WHERE	o.cust_code = @customer AND
--					o.ship_to = @ship_to AND
					-- o.type = 'I' AND								-- Include Credits and Sales
					(o.status >= 'R' AND o.status <> 'V') AND
					(o.date_entered BETWEEN @start_date AND @end_date) AND
					(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)

			-- Load historic orders
			INSERT INTO #orders ( order_no, ext, total_amt_order, user_category, promo_id, promo_level, historic, order_no_text, type )
			--SELECT	CAST('-' + SUBSTRING(o.order_no,3,(LEN(o.order_no) - 2)) AS INT), o.ext, o.total_amt_order, o.user_category, NULL, NULL,1,CAST(o.order_no AS VARCHAR(20))
			SELECT	o.order_no, o.ext, CASE WHEN o.type = 'C' THEN (o.total_amt_order * -1) ELSE o.total_amt_order END, -- v2.1
					o.user_category, 
					IsNull(CAST(user_def_fld3 AS VARCHAR(20)),''), IsNull(CAST(user_def_fld9 AS VARCHAR(30)),''),					-- v2.0
					1,CAST(o.order_no AS VARCHAR(20)), o.type -- v1.4
			FROM	cvo_orders_all_hist o (NOLOCK)
			WHERE	o.cust_code = @customer AND
					o.ship_to = @ship_to AND 
					-- o.type = 'I' AND								-- Include Credits and Sales
					(o.status >= 'R' AND o.status <> 'V') AND
					(o.date_entered BETWEEN @start_date AND @end_date) AND
					(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
			-- END v1.3

			-- START v2.9
			-- Load order types for this line
			DELETE FROM #cvo_customer_qualifications_order_type
			INSERT INTO #cvo_customer_qualifications_order_type(
				line_no,
				order_type)
			SELECT
				line_no,
				order_type
			FROM
				dbo.CVO_promotions_cust_order_type (NOLOCK)
			WHERE
				promo_id = @promo_id
				AND promo_level = @promo_level
				AND line_no = @line_no

			-- Load attributes for this line
			DELETE FROM #cvo_customer_qualifications_attribute
			INSERT INTO #cvo_customer_qualifications_attribute(
				line_no,
				attribute)
			SELECT
				line_no,
				attribute
			FROM
				dbo.CVO_promotions_attribute (NOLOCK)
			WHERE
				promo_id = @promo_id
				AND promo_level = @promo_level
				AND line_no = @line_no
				AND line_type = 'C'
			-- END v2.9

			-- START v3.1
			-- Load genders for this line
			DELETE FROM #cvo_customer_qualifications_gender
			INSERT INTO #cvo_customer_qualifications_gender(
				line_no,
				gender)
			SELECT
				line_no,
				gender
			FROM
				dbo.CVO_promotions_gender (NOLOCK)
			WHERE
				promo_id = @promo_id
				AND promo_level = @promo_level
				AND line_no = @line_no
				AND line_type = 'C'
			-- END v3.1

			-- START v1.2 - min/max sales
			SET @order_sales = 0
			SET @historic_sales = 0	-- v1.3

			-- 1. Get total sales
			-- Brand Only
			IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') = ''
			BEGIN
				-- START v2.9 
				-- Get order sales
				-- v4.0 Start
				IF (ISNULL(@attribute,0) = 0)
				BEGIN
					SELECT 
						@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
						@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
					FROM
						#orders o (NOLOCK)
					INNER JOIN
						dbo.cvo_order_line_sales_vw v (NOLOCK)
					ON
						o.order_no = v.order_no
						AND o.ext = v.order_ext
-- v4.4					LEFT JOIN 
-- v4.4						#cvo_customer_qualifications_attribute a
-- v4.4					ON
-- v4.4						v.attribute = a.attribute
					LEFT JOIN
						#cvo_customer_qualifications_order_type t
					ON 
						o.user_category = t.order_type
					-- START v3.1
					LEFT JOIN
						#cvo_customer_qualifications_gender g
					ON 
						v.gender = g.gender
					-- END 3.1
					WHERE	
						((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						-- START v3.1
						AND ((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						--AND ((ISNULL(@gender,'') = '') OR (v.gender = @gender))
						-- END v3.1
						AND ((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4						AND ((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
				END
				ELSE
				BEGIN
					IF (@brand_exclude = 'Y')
					BEGIN
						SELECT	@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
								@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
						FROM	#orders o (NOLOCK)
						INNER JOIN dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)

						SELECT	@att_sales = ISNULL(SUM(line_amt),0), 
								@att_count = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
						FROM	#orders o (NOLOCK)
						JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						JOIN	cvo_part_attributes x (NOLOCK)
						ON		v.part_no = x.part_no	
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
						AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)

						SET @order_sales = @order_sales - ISNULL(@att_sales,0.0)
						SET @order_pieces = @order_pieces - ISNULL(@att_count,0.0)
					END
					ELSE
					BEGIN

						SELECT	@order_sales = ISNULL(SUM(line_amt),0), 
								@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
						FROM	#orders o (NOLOCK)
						JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						JOIN	cvo_part_attributes x (NOLOCK)
						ON		v.part_no = x.part_no	
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
						AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
					END
				END
				-- v4.0 End

				/*
				-- START v1.3
				-- Get current order sales
				SELECT 
					@order_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.orders_all o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					o.order_no = v.order_no
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND ((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
					AND v.historic = 0
	
				-- Get historic order sales
				SELECT 
					@historic_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.cvo_orders_all_hist o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					--o.order_no = v.order_no_text
					o.order_no = v.order_no -- v1.4
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND ((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
					AND v.historic = 1
				

				SET @order_sales = ISNULL(@order_sales,0) + ISNULL(@historic_sales,0)
				-- END v1.3
				*/
				-- END v2.9
			END

			-- Category Only
			IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') <> ''
			BEGIN
				-- START v2.9
				-- Get order sales
				-- v4.0 Start
				IF (ISNULL(@attribute,0) = 0)
				BEGIN
					SELECT 
						@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
						@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
					FROM
						#orders o (NOLOCK)
					INNER JOIN
						dbo.cvo_order_line_sales_vw v (NOLOCK)
					ON
						o.order_no = v.order_no
						AND o.ext = v.order_ext
-- v4.4					LEFT JOIN 
-- v4.4						#cvo_customer_qualifications_attribute a
-- v4.4					ON
-- v4.4						v.attribute = a.attribute
					LEFT JOIN
						#cvo_customer_qualifications_order_type t
					ON 
						o.user_category = t.order_type
					-- START v3.1
					LEFT JOIN
						#cvo_customer_qualifications_gender g
					ON 
						v.gender = g.gender
					-- END 3.1
					WHERE	
						((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						-- START v3.1
						AND ((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						--AND ((ISNULL(@gender,'') = '') OR (v.gender = @gender))
						-- END v3.1
						AND ((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4						AND ((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
				END
				ELSE
				BEGIN
					IF (@category_exclude = 'Y')
					BEGIN
						SELECT	@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
								@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
						FROM	#orders o (NOLOCK)
						INNER JOIN dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)


						SELECT	@att_sales = ISNULL(SUM(line_amt),0), 
								@att_count = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
						FROM	#orders o (NOLOCK)
						JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						JOIN	cvo_part_attributes x (NOLOCK)
						ON		v.part_no = x.part_no	
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
						AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)

						SET @order_sales = @order_sales - ISNULL(@att_sales,0.0)
						SET @order_pieces = @order_pieces - ISNULL(@att_count,0.0)
					END
					ELSE
					BEGIN
						SELECT	@order_sales = ISNULL(SUM(line_amt),0), 
								@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
						FROM	#orders o (NOLOCK)
						JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						JOIN	cvo_part_attributes x (NOLOCK)
						ON		v.part_no = x.part_no	
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
						AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
					END
				END

				/*
				-- START v1.3
				-- Get current order sales
				SELECT 
					@order_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.orders_all o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					o.order_no = v.order_no
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND ((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
					AND v.historic = 0
				
				-- Get historic order sales
				SELECT 
					@historic_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.cvo_orders_all_hist o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					--o.order_no = v.order_no_text
					o.order_no = v.order_no -- v1.4
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND ((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
					AND v.historic = 1
				
				SET @order_sales = ISNULL(@order_sales,0) + ISNULL(@historic_sales,0)
				-- END v1.3
				*/
				-- END v2.9			
			END

			-- Brand and Category
			IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') <> ''
			BEGIN
				-- START v2.9 
				-- Get order sales
				-- v4.0 Start
				IF (ISNULL(@attribute,0) = 0)
				BEGIN
					SELECT 
						@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
						@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
					FROM
						#orders o (NOLOCK)
					INNER JOIN
						dbo.cvo_order_line_sales_vw v (NOLOCK)
					ON
						o.order_no = v.order_no
						AND o.ext = v.order_ext
-- v4.4					LEFT JOIN 
-- v4.4						#cvo_customer_qualifications_attribute a
-- v4.4					ON
-- v4.4						v.attribute = a.attribute
					LEFT JOIN
						#cvo_customer_qualifications_order_type t
					ON 
						o.user_category = t.order_type
					-- START v3.1
					LEFT JOIN
						#cvo_customer_qualifications_gender g
					ON 
						v.gender = g.gender
					-- END 3.1
					WHERE	
						((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND ((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						-- START v3.1
						AND ((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						--AND ((ISNULL(@gender,'') = '') OR (v.gender = @gender))
						-- END v3.1
						AND ((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4						AND ((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
				END
				ELSE
				BEGIN
					IF (@brand_exclude = 'Y' OR @category_exclude = 'Y')
					BEGIN
						SELECT	@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
								@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
						FROM	#orders o (NOLOCK)
						INNER JOIN dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)

						SELECT	@att_sales = ISNULL(SUM(line_amt),0), 
								@att_count = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
						FROM	#orders o (NOLOCK)
						JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						JOIN	cvo_part_attributes x (NOLOCK)
						ON		v.part_no = x.part_no	
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
						AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)

						SET @order_sales = @order_sales - ISNULL(@att_sales,0.0)
						SET @order_pieces = @order_pieces - ISNULL(@att_count,0.0)
					END
					ELSE
					BEGIN
						SELECT	@order_sales = ISNULL(SUM(line_amt),0), 
								@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
						FROM	#orders o (NOLOCK)
						JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
						ON		o.order_no = v.order_no
						AND		o.ext = v.order_ext
						JOIN	cvo_part_attributes x (NOLOCK)
						ON		v.part_no = x.part_no	
						LEFT JOIN #cvo_customer_qualifications_order_type t
						ON		o.user_category = t.order_type
						LEFT JOIN #cvo_customer_qualifications_gender g
						ON		v.gender = g.gender
						WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
						AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
						AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
						AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
					END

				END
				-- v4.0 End

				/*
				-- START v1.3
				-- Get current order sales
				SELECT 
					@order_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.orders_all o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					o.order_no = v.order_no
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND ((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
					AND ((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
					AND v.historic = 0

				-- Get historic order sales
				SELECT 
					@historic_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.cvo_orders_all_hist o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					--o.order_no = v.order_no_text
					o.order_no = v.order_no -- v1.4
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND ((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
					AND ((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
					AND v.historic = 1
				
				SET @order_sales = ISNULL(@order_sales,0) + ISNULL(@historic_sales,0)
				-- END v1.3
				*/
				-- END v2.9
			END

			-- No Brand or Category
			IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') = ''
			BEGIN
				-- START v2.7 
				-- Get order sales
				-- v4.0 Start
				IF (ISNULL(@attribute,0) = 0)
				BEGIN
					SELECT 
						@order_sales = ISNULL(SUM(line_amt),0), -- v2.1 -- v2.6
						@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)		
					FROM
						#orders o (NOLOCK)
					INNER JOIN
						dbo.cvo_order_line_sales_vw v (NOLOCK)
					ON
						o.order_no = v.order_no
						AND o.ext = v.order_ext
-- v4.4					LEFT JOIN 
-- v4.4						#cvo_customer_qualifications_attribute a
-- v4.4					ON
-- v4.4						v.attribute = a.attribute
					LEFT JOIN
						#cvo_customer_qualifications_order_type t
					ON 
						o.user_category = t.order_type
					-- START v3.1
					LEFT JOIN
						#cvo_customer_qualifications_gender g
					ON 
						v.gender = g.gender
					-- END 3.1
					WHERE	
						-- START v3.1
						((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
						--(ISNULL(@gender,'') = '') OR (v.gender = @gender))
						-- END v3.1
						AND ((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4						AND ((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)

				END
				ELSE
				BEGIN
					SELECT	@order_sales = ISNULL(SUM(line_amt),0), 
							@order_pieces = ISNULL(SUM(ISNULL(piece_qty,0)),0)	
					FROM	#orders o (NOLOCK)
					JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
					ON		o.order_no = v.order_no
					AND		o.ext = v.order_ext
					JOIN	cvo_part_attributes x (NOLOCK)
					ON		v.part_no = x.part_no	
					LEFT JOIN #cvo_customer_qualifications_order_type t
					ON		o.user_category = t.order_type
					LEFT JOIN #cvo_customer_qualifications_gender g
					ON		v.gender = g.gender
					WHERE	((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
					AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
					AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
				END
				-- v4.0 End
				/*
				-- START v1.3
				-- Get current order sales
				SELECT 
					@order_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.orders_all o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					o.order_no = v.order_no
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND v.historic = 0

				-- Get historic order sales
				SELECT 
					@historic_sales = ISNULL(SUM(line_amt),0) -- v2.1 -- v2.6
				FROM
					dbo.cvo_orders_all_hist o (NOLOCK)
				INNER JOIN
					dbo.cvo_order_line_sales_vw v (NOLOCK)
				ON
					--o.order_no = v.order_no_text
					o.order_no = v.order_no -- v1.4
					AND o.ext = v.order_ext
				WHERE	
					o.cust_code = @customer 													
					AND o.status >= 'R' 
					AND o.status <> 'V' 
					AND (o.date_entered BETWEEN @start_date AND @end_date) 
					AND	(CAST(o.order_no AS VARCHAR(20)) + '-' + CAST(o.ext AS VARCHAR(20)) <> @so_ext)
					AND v.historic = 1
				
				SET @order_sales = ISNULL(@order_sales,0) + ISNULL(@historic_sales,0)
				-- END v1.3
				*/
				-- END v2.9
			END

			-- START v2.9 - check if no_of_pieces criteria is met
			-- START v3.2
			IF NOT ((ISNULL(@no_of_pieces,@order_pieces)  <= @order_pieces) AND (ISNULL(@max_no_of_pieces,@order_pieces)  >= @order_pieces))
			--IF ISNULL(@no_of_pieces,@order_pieces)  > @order_pieces
			BEGIN
				SELECT @achived = 0
				SET @fail_reason = 'Customer does not qualify for promotion - prior Sales Orders do not fall within the minimum/maximum number of pieces value.' 
				--SET @fail_reason = 'Customer does not qualify for promotion - prior Sales Orders do not meet number of pieces value.' 
			-- END v3.2
			END
			ELSE
			BEGIN
				SELECT @achived = 1
			END			

			-- 2. Check if total sales are between min and max values
			IF (@order_sales >= @min_sales) AND (@order_sales <= @max_sales) AND @achived = 1
			-- IF (@order_sales >= @min_sales) AND (@order_sales <= @max_sales)
			-- END v2.9
			BEGIN
				SELECT @achived = 1
			END
			ELSE
			BEGIN
				SELECT @achived = 0
				-- START v2.9
				IF @fail_reason = ''
				BEGIN
					SET @fail_reason = 'Customer/Ship To does not qualify for promotion - prior Sales Orders do not fall within the minimum/maximum sales values.' -- v1.1
				END
				-- END v2.9
			END

			-- START v3.6
			IF ISNULL(@pp_not_purchased,0) = 1
			BEGIN
				IF ISNULL(@past_promo_id, '') <> '' AND ISNULL(@past_promo_level, '') <> ''
				BEGIN
					--	Has the customer ordered any of the past programs within the selected dates (fail if they have)
					IF (((SELECT COUNT(1) FROM #orders WHERE promo_id = @past_promo_id AND promo_level = @past_promo_level) = 0) AND @achived = 1)
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						IF @fail_reason = ''
						BEGIN
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - customer has ordered the past promotion within the set dates.' 
						END
					END
				END
			END
			ELSE
			BEGIN

				--	Has the customer/Ship To ordered any of the past programs within the selected dates
				IF ((((SELECT COUNT(*) FROM #orders WHERE promo_id = @past_promo_id AND promo_level = @past_promo_level) > 0) OR
					(LEN(RTRIM(ISNULL(@past_promo_id, ''))) = 0 AND LEN(RTRIM(ISNULL(@past_promo_level, ''))) = 0)) AND @achived = 1)
				BEGIN
					SELECT @achived = 1
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					-- START v1.1
					IF @fail_reason = ''
					BEGIN
						SET @fail_reason = 'Customer/Ship To does not qualify for promotion - customer/ship to has not ordered any of the past promotions within the required dates.' -- v1.1
					END
					-- END v1.1
				END
			END
			-- END v3.6

			--	Does the customer/Ship To have at least the minimum/maximum Rx orders withint the selected dates.
			IF (@achived = 1)
			BEGIN
				SELECT @rows_rx = COUNT(*) FROM #orders WHERE user_category = 'RX' and type = 'I'
				SELECT @rows_rx = @rows_rx - COUNT(*) FROM #orders WHERE user_category = 'RX' and type = 'C'
				SELECT @max = COUNT(*) FROM #orders
				IF @rows_rx > 0
				BEGIN
					SELECT @per_rx_order = (@rows_rx * 100) / @max
					IF (@per_rx_order >= IsNull(@min_rx_per,0) AND @per_rx_order <= IsNull(@max_rx_per,999))			-- TLM : Fix
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						SET @fail_reason = 'Customer/Ship To does not qualify for promotion - minimum/maximum RX orders requirement.' -- v1.1
					END
				END
			END

			--  Does the customer/Ship To have no more than the max Returns % withint the selected dates.
			IF (@achived = 1)
			BEGIN
				-- START v1.3
				SET @returns = 0
				
				-- Get current returns
				SELECT	
					@returns = COUNT(*)
				FROM	
					orders_all o (NOLOCK)
				INNER JOIN 
					#orders t 
				ON 
					o.orig_no = t.order_no AND o.orig_ext = t.ext 
				WHERE	
					o.type = 'C'
					AND t.historic = 0
				-- END v1.3

				IF @returns > 0 AND @return_per <> 0 -- v2.5
				BEGIN
					SELECT @per_return = (@returns * 100) / @max
					IF @per_return <= IsNull(@return_per,0)								-- TLM : Fix
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						SET @fail_reason = 'Customer/Ship To does not qualify for promotion - customer/ship to exceeds the maximum returns percentage.' -- v1.1
					END
				END
			END

			--   Has the customer/Ship To order or not ordered a given brand or category of product within the selected dates
			IF (@achived = 1)
			BEGIN
				-- START v1.3
				-- Load current order lines
				INSERT INTO #ord_list (part_no, brand, category)
				SELECT DISTINCT l.part_no, i.category, i.type_code
				FROM 
					#orders o
				INNER JOIN 
					ord_list l (NOLOCK)
				ON 
					o.order_no = l.order_no 
					AND o.ext = l.order_ext
				INNER JOIN 
					inv_master i (NOLOCK)
				ON 
					l.part_no = i.part_no
				WHERE
					o.historic = 0

				-- Load historic order lines
				INSERT INTO #ord_list (part_no, brand, category)
				SELECT DISTINCT l.part_no, i.category, i.type_code
				FROM 
					#orders o
				INNER JOIN 
					cvo_ord_list_hist l (NOLOCK)
				ON 
					--o.order_no_text = l.order_no 
					o.order_no = l.order_no -- v1.4
					AND o.ext = l.order_ext
				INNER JOIN 
					inv_master i (NOLOCK)
				ON 
					l.part_no = i.part_no
				WHERE
					o.historic = 1

				-- END v1.3

				
				SELECT @brand_found = 0, @category_found = 0
				SELECT @brand_found = COUNT(*) FROM #ord_list WHERE brand = @brand
				SELECT @category_found = COUNT(*) FROM #ord_list WHERE category = @category

				IF (SELECT COUNT(*) FROM #ord_list) > 0
				BEGIN
					IF @brand_exclude = 'Y'
					BEGIN
						IF (LEN(RTRIM(@brand))>0 AND LEN(RTRIM(@category))>0)
							IF (@brand_found > 0 AND @category_found > 0)
							BEGIN
								SELECT @achived = 1
							END
							ELSE
							BEGIN
								SELECT @achived = 0
								SET @fail_reason = 'Customer/Ship To does not qualify for promotion - excluded brand or category.' -- v1.1
							END
						ELSE
							IF (@brand_found > 0 OR @category_found > 0)
							BEGIN
								SELECT @achived = 1
							END
							ELSE
							BEGIN
								SELECT @achived = 0
								SET @fail_reason = 'Customer/Ship To does not qualify for promotion - excluded brand or category.' -- v1.1
							END
					END
				DELETE FROM #ord_list
				END
			END
			
			-- v3.8 Start
			-- Stock Orders
			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') = ''
				BEGIN

					IF (ISNULL(@stock_orders_pieces,0) > 0) AND (ISNULL(@min_stock_orders,0) > 0 OR ISNULL(@max_stock_orders,0) > 0)
					BEGIN
						IF (@min_stock_orders IS NULL)
							SET @min_stock_orders = 0
						IF (@max_stock_orders IS NULL)
							SET @max_stock_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN

							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.4							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.4							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
							AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'ST'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
							HAVING SUM(piece_qty) >= @stock_orders_pieces
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							IF (@brand_exclude = 'Y')
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								INSERT	#att_count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders

								SET @att_order_cnt = 0
								SELECT	@att_order_cnt =COUNT(1)
								FROM	#att_count_orders

								SET @order_cnt = @order_cnt - @att_order_cnt
							END
							ELSE
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders
							END
						END
						-- v4.0 End

						IF (@order_cnt < @min_stock_orders OR @order_cnt > @max_stock_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - Stock Orders do not fall within the minimum/maximum number for the pieces specified.' 					
						END
					END
				END
			END

			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') <> ''
				BEGIN

					IF (ISNULL(@stock_orders_pieces,0) > 0) AND (ISNULL(@min_stock_orders,0) > 0 OR ISNULL(@max_stock_orders,0) > 0)
					BEGIN
						IF (@min_stock_orders IS NULL)
							SET @min_stock_orders = 0
						IF (@max_stock_orders IS NULL)
							SET @max_stock_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.0							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.0							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
							AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.0							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'ST'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
							HAVING SUM(piece_qty) >= @stock_orders_pieces
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							IF (@category_exclude = 'Y')
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								INSERT	#att_count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders

								SET @att_order_cnt = 0
								SELECT	@att_order_cnt =COUNT(1)
								FROM	#att_count_orders

								SET @order_cnt = @order_cnt - @att_order_cnt
							END
							ELSE
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders
							END
						END
						-- v4.0 End

						IF (@order_cnt < @min_stock_orders OR @order_cnt > @max_stock_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - Stock Orders do not fall within the minimum/maximum number for the pieces specified.' 					
						END
					END
				END
			END

			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') <> ''
				BEGIN

					IF (ISNULL(@stock_orders_pieces,0) > 0) AND (ISNULL(@min_stock_orders,0) > 0 OR ISNULL(@max_stock_orders,0) > 0)
					BEGIN
						IF (@min_stock_orders IS NULL)
							SET @min_stock_orders = 0
						IF (@max_stock_orders IS NULL)
							SET @max_stock_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN

							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.4							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.4							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
							AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
							AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'ST'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
							HAVING SUM(piece_qty) >= @stock_orders_pieces
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							IF (@brand_exclude = 'Y' OR @category_exclude = 'Y')
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								INSERT	#att_count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders

								SET @att_order_cnt = 0
								SELECT	@att_order_cnt =COUNT(1)
								FROM	#att_count_orders

								SET @order_cnt = @order_cnt - @att_order_cnt
							END
							ELSE
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'ST'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders
							END
						END
						-- v4.0 End
							

						IF (@order_cnt < @min_stock_orders OR @order_cnt > @max_stock_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - Stock Orders do not fall within the minimum/maximum number for the pieces specified.' 					
						END
					END
				END
			END

			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') = ''
				BEGIN

					IF (ISNULL(@stock_orders_pieces,0) > 0) AND (ISNULL(@min_stock_orders,0) > 0 OR ISNULL(@max_stock_orders,0) > 0)
					BEGIN
						IF (@min_stock_orders IS NULL)
							SET @min_stock_orders = 0
						IF (@max_stock_orders IS NULL)
							SET @max_stock_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.4							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.4							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.4							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'ST'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
							HAVING SUM(piece_qty) >= @stock_orders_pieces
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
							JOIN	cvo_part_attributes x (NOLOCK)
							ON		v.part_no = x.part_no	
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'ST'
							AND		RIGHT(o.user_category,2) <> 'RB'
							AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
							GROUP BY o.order_no, o.ext
							HAVING SUM(piece_qty) >= @stock_orders_pieces

							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
					END
						-- v4.0
					

						IF (@order_cnt < @min_stock_orders OR @order_cnt > @max_stock_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - Stock Orders do not fall within the minimum/maximum number for the pieces specified.' 					
						END
					END
				END
			END

			-- RX Orders
			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') = ''
				BEGIN

					IF (ISNULL(@min_rx_orders,0) > 0 OR ISNULL(@max_rx_orders,0) > 0)
					BEGIN
						IF (@min_rx_orders IS NULL)
							SET @min_rx_orders = 0
						IF (@max_rx_orders IS NULL)
							SET @max_rx_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.0							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.0							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
							AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.0							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'RX'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders						
						END
						ELSE
						BEGIN
							IF (@brand_exclude = 'Y')
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								INSERT	#att_count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders

								SET @att_order_cnt = 0
								SELECT	@att_order_cnt =COUNT(1)
								FROM	#att_count_orders

								SET @order_cnt = @order_cnt - @att_order_cnt
							END
							ELSE
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders
							END
						END
						-- v4.0 End
						IF (@order_cnt < @min_rx_orders OR @order_cnt > @max_rx_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - RX Re-Orders do not fall within the minimum/maximum number specified.' 					
						END
					END
				END
			END

			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') <> ''
				BEGIN

					IF (ISNULL(@min_rx_orders,0) > 0 OR ISNULL(@max_rx_orders,0) > 0)
					BEGIN
						IF (@min_rx_orders IS NULL)
							SET @min_rx_orders = 0
						IF (@max_rx_orders IS NULL)
							SET @max_rx_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.0							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.0							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
							AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.0							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'RX'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							IF (@category_exclude = 'Y')
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								INSERT	#att_count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders

								SET @att_order_cnt = 0
								SELECT	@att_order_cnt =COUNT(1)
								FROM	#att_count_orders

								SET @order_cnt = @order_cnt - @att_order_cnt
							END
							ELSE
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders
							END
						END
						-- v4.0 End	

						IF (@order_cnt < @min_rx_orders OR @order_cnt > @max_rx_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - RX Re-Orders do not fall within the minimum/maximum number specified.' 									
						END
					END
				END
			END

			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') <> ''
				BEGIN

					IF (ISNULL(@min_rx_orders,0) > 0 OR ISNULL(@max_rx_orders,0) > 0)
					BEGIN
						IF (@min_rx_orders IS NULL)
							SET @min_rx_orders = 0
						IF (@max_rx_orders IS NULL)
							SET @max_rx_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.0							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.0							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
							AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
							AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.0							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'RX'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							IF (@brand_exclude = 'Y' OR @category_exclude = 'Y')
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								INSERT	#att_count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders

								SET @att_order_cnt = 0
								SELECT	@att_order_cnt =COUNT(1)
								FROM	#att_count_orders

								SET @order_cnt = @order_cnt - @att_order_cnt
							END
							ELSE
							BEGIN
								INSERT	#count_orders (order_no, order_ext, rec_count)
								SELECT	o.order_no, o.ext, COUNT(1)
								FROM	#orders o (NOLOCK)
								JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
								ON		o.order_no = v.order_no
								AND		o.ext = v.order_ext
								JOIN	cvo_part_attributes x (NOLOCK)
								ON		v.part_no = x.part_no	
								LEFT JOIN #cvo_customer_qualifications_order_type t
								ON		o.user_category = t.order_type
								LEFT JOIN #cvo_customer_qualifications_gender g
								ON		v.gender = g.gender
								WHERE	((v.brand = @brand AND @brand_exclude = 'N') OR (v.brand <> @brand AND @brand_exclude = 'Y'))
								AND		((v.category = @category AND @category_exclude = 'N') OR (v.category <> @category AND @category_exclude = 'Y'))
								AND		((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
								AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
								AND		LEFT(o.user_category,2) = 'RX'
								AND		RIGHT(o.user_category,2) <> 'RB'
								AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
								GROUP BY o.order_no, o.ext
								HAVING SUM(piece_qty) >= @stock_orders_pieces

								SET @order_cnt = 0
								SELECT	@order_cnt =COUNT(1)
								FROM	#count_orders
							END
						END
						-- v4.0 End							

						IF (@order_cnt < @min_rx_orders OR @order_cnt > @max_rx_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - RX Re-Orders do not fall within the minimum/maximum number specified.' 		
						END
					END
				END
			END

			IF (@achived = 1)
			BEGIN
				IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') = ''
				BEGIN

					IF (ISNULL(@min_rx_orders,0) > 0 OR ISNULL(@max_rx_orders,0) > 0)
					BEGIN
						IF (@min_rx_orders IS NULL)
							SET @min_rx_orders = 0
						IF (@max_rx_orders IS NULL)
							SET @max_rx_orders = 32000

						TRUNCATE TABLE #count_orders
						TRUNCATE TABLE #att_count_orders -- v4.0
						-- v4.0 Start
						IF (ISNULL(@attribute,0) = 0)
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
-- v4.0							LEFT JOIN #cvo_customer_qualifications_attribute a
-- v4.0							ON		v.attribute = a.attribute
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
-- v4.0							AND		((ISNULL(@attribute,0) = 0) OR (ISNULL(@attribute,0) = 1)  AND a.attribute IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'RX'
							AND		RIGHT(o.user_category,2) <> 'RB'
							GROUP BY o.order_no, o.ext
			
							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						ELSE
						BEGIN
							INSERT	#count_orders (order_no, order_ext, rec_count)
							SELECT	o.order_no, o.ext, COUNT(1)
							FROM	#orders o (NOLOCK)
							JOIN	dbo.cvo_order_line_sales_vw v (NOLOCK)
							ON		o.order_no = v.order_no
							AND		o.ext = v.order_ext
							JOIN	cvo_part_attributes x (NOLOCK)
							ON		v.part_no = x.part_no	
							LEFT JOIN #cvo_customer_qualifications_order_type t
							ON		o.user_category = t.order_type
							LEFT JOIN #cvo_customer_qualifications_gender g
							ON		v.gender = g.gender
							WHERE	((ISNULL(@gender_check,0) = 0) OR (ISNULL(@gender_check,0) = 1)  AND g.gender IS NOT NULL)
							AND		((ISNULL(@order_type,0) = 0) OR (o.[type] = 'C') OR (ISNULL(@order_type,0) = 1)  AND o.[type] = 'I' AND t.order_type IS NOT NULL)
							AND		LEFT(o.user_category,2) = 'RX'
							AND		RIGHT(o.user_category,2) <> 'RB'
							AND		x.attribute IN (SELECT attribute FROM #cvo_customer_qualifications_attribute)
							GROUP BY o.order_no, o.ext
							HAVING SUM(piece_qty) >= @stock_orders_pieces

							SET @order_cnt = 0
							SELECT	@order_cnt =COUNT(1)
							FROM	#count_orders
						END
						-- v4.0 End

						IF (@order_cnt < @min_rx_orders OR @order_cnt > @max_rx_orders)
						BEGIN 
							SELECT @achived = 0
							SET @fail_reason = 'Customer/Ship To does not qualify for promotion - RX Re-Orders do not fall within the minimum/maximum number specified.' 				
						END
					END
				END
			END
			-- v3.8 End



			-- Verify if conditions were achived	
			IF @achived > 0 
			BEGIN
				UPDATE #cvo_customer_qualifications SET rows_found = '1=1'
				WHERE id = @id
			END

			-- DELETE ALL ORDER FROM TEMP TABLE			
			DELETE FROM #orders

			SELECT	@id = MIN(id)
			FROM	#cvo_customer_qualifications
			WHERE	id > @id
		END

		CREATE TABLE #t(r INT)

		SELECT @condition = 'IF '
		SELECT @counter = 0

		SELECT	@max = COUNT(*)	FROM #cvo_customer_qualifications

		SELECT	@id = MIN(id)
		FROM	#cvo_customer_qualifications		

		WHILE (@id IS NOT NULL)
		BEGIN
			SELECT	@rows_found = rows_found, @cond1 = and_, @cond2 = or_
			FROM 	#cvo_customer_qualifications
			WHERE	id = @id
			
			SELECT @counter = @counter + 1

			SELECT @condition = @condition + @rows_found 
			
			IF @cond1 = 'Y' AND @counter <> @max
				SELECT @condition = @condition + ' AND '
			ELSE
				IF @cond2 = 'Y' AND @counter <> @max
					SELECT @condition = @condition + ' OR '

			-- v2.2
			IF @cond1 = 'N' AND @cond2 = 'N' AND @counter <> @max
				SELECT @condition = @condition + ' AND '

			SELECT	@id = MIN(id)
			FROM	#cvo_customer_qualifications
			WHERE	id > @id
		END 

		EXEC (@condition + ' INSERT INTO #t VALUES(1) ELSE INSERT INTO #t VALUES (0)')
	
		-- START v2.7
		IF @sub_check = 0
		BEGIN
			SELECT r as code, CASE WHEN r = 1 THEN '' ELSE @fail_reason END as reason FROM #t	-- v1.1 v3.9
		END
		-- END v2.7

		DROP TABLE #cvo_customer_qualifications
		-- DROP TABLE #t -- v2.7
		DROP TABLE #orders
		DROP TABLE #ord_list
		-- START v2.9
		DROP TABLE #cvo_customer_qualifications_order_type
		DROP TABLE #cvo_customer_qualifications_attribute
		-- END v2.9
		DROP TABLE #cvo_customer_qualifications_gender -- v3.1

		-- START v2.7
		IF @sub_check = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM #t WHERE r = 1)
			BEGIN
				DROP TABLE #t
				RETURN 1
			END
			ELSE
			BEGIN
				DROP TABLE #t
				RETURN 0
			END
		END
		-- END v2.7
END

GO
GRANT EXECUTE ON  [dbo].[CVO_verify_customer_shipto_quali_sp] TO [public]
GO
