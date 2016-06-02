SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE 	[dbo].[cc_load_collections_sp] 	@search_value varchar(41),
													@search_type tinyint,
													@workload_code varchar(8) = NULL,
													@all_org_flag			smallint = 0,	 
													@from_org varchar(30) = '',
													@to_org varchar(30) = ''


AS







SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF

DECLARE 	@db_date 	int,
			@unposted 	int,
			@orders		int,
			@contacts	int,
			@comments	int,
			@db_date_str varchar(12),
			@parent	varchar(8),
			@parent_name varchar(40),
			@parent_type varchar(8),
			@price_class_desc varchar(40),
			@open_orders decimal(28,2),
			@cust_code varchar(8),
			@date_entered int,
			@last_check varchar(16),
			@last_amt	float,
			@open_orders2 decimal(28,2),
			@IsParent int, -- v1.1
			@IsBG int, -- v1.3
			@relation_code varchar(10) -- v1.3

CREATE TABLE #cust
(	customer_code			varchar(8) NULL, 
	territory_code		varchar(8) NULL, 
	terms_code				varchar(8) NULL, 
	salesperson_code	varchar(8) NULL,
	terms_desc				varchar(40) NULL,
	territory_desc		varchar(40) NULL,
	salesperson_name	varchar(40) NULL,
	status						varchar(5) NULL)

	CREATE TABLE #customers( customer_code varchar(8) )


IF ( ISNULL(DATALENGTH(LTRIM(RTRIM(@workload_code))),0) = 0 )
	BEGIN
		IF (@search_type = 1)
			INSERT #cust(customer_code,territory_code,terms_code,salesperson_code)
			SELECT 	customer_code,	territory_code,	terms_code,salesperson_code
			FROM arcust (NOLOCK)
			WHERE customer_code = @search_value
		IF (@search_type = 2)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust (NOLOCK)
			WHERE customer_code = (SELECT min(customer_code) FROM arcust)

		IF (@search_type = 3)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust (NOLOCK)
			WHERE customer_code = (SELECT max(customer_code) FROM arcust)

		IF (@search_type = 4)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust (NOLOCK)
			WHERE customer_name = @search_value

		IF (@search_type = 5)
			BEGIN
				SET ROWCOUNT 1
				INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
				SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
				FROM arcust (NOLOCK)
				WHERE customer_code > @search_value
				order by customer_code ASC
				SET ROWCOUNT 0
			END

		IF (@search_type = 6)
			BEGIN
				SET ROWCOUNT 1
				INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
				SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
				FROM arcust (NOLOCK)
				WHERE customer_code < @search_value
				order by customer_code DESC
				SET ROWCOUNT 0
			END
	END
ELSE
	BEGIN
		IF (@search_type = 1)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	c.customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust c (NOLOCK),ccwrkmem m (NOLOCK)
			WHERE c.customer_code = @search_value
			AND m.workload_code = @workload_code
			AND m.customer_code = c.customer_code

		IF (@search_type = 2)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust (NOLOCK)
			WHERE customer_code = (SELECT min(customer_code) FROM ccwrkmem (NOLOCK)
						 WHERE workload_code = @workload_code)

		IF (@search_type = 3)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust (NOLOCK)
			WHERE customer_code = (SELECT max(customer_code) FROM ccwrkmem (NOLOCK)
						 WHERE workload_code = @workload_code)

		IF (@search_type = 4)
			INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
			SELECT 	c.customer_code,	territory_code,	terms_code,salesperson_code 
			FROM arcust c (NOLOCK),ccwrkmem m (NOLOCK)
			WHERE c.customer_name = @search_value
			AND m.workload_code = @workload_code
			AND m.customer_code = c.customer_code
	
		IF (@search_type = 5)
			BEGIN
				SET ROWCOUNT 1
				INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
				SELECT 	c.customer_code,	territory_code,	terms_code,salesperson_code 
				FROM arcust c (NOLOCK),ccwrkmem m (NOLOCK)
				WHERE c.customer_code > @search_value
				AND m.workload_code = @workload_code
				AND m.customer_code = c.customer_code
				order by c.customer_code ASC
				SET ROWCOUNT 0
			END

		IF (@search_type = 6)
			BEGIN
				SET ROWCOUNT 1
				INSERT #cust(customer_code,	territory_code,	terms_code,salesperson_code )
				SELECT 	c.customer_code,	territory_code,	terms_code,salesperson_code 
				FROM arcust c (NOLOCK),ccwrkmem m (NOLOCK)
				WHERE c.customer_code < @search_value
				AND m.workload_code = @workload_code
				AND m.customer_code = c.customer_code
				order by c.customer_code DESC
				SET ROWCOUNT 0
			END
	END

	INSERT #customers
	SELECT customer_code FROM #cust

	SELECT @cust_code = customer_code FROM #cust


	-- WORKING TABLE
	IF OBJECT_ID('tempdb..#bg_data') IS NOT NULL
		DROP TABLE #bg_data

	CREATE TABLE #bg_data (
		doc_ctrl_num	varchar(16),
		order_ctrl_num	varchar(16),
		customer_code	varchar(10),
		doc_date_int	int,
		doc_date		varchar(10),
		parent			varchar(10))

	-- Call BG Data Proc
	EXEC cvo_bg_get_document_data_sp @cust_code, 1
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)


	UPDATE #cust
	SET 	terms_desc = t.terms_desc
	FROM #cust c LEFT OUTER JOIN arterms t (NOLOCK) ON (c.terms_code = t.terms_code)

	UPDATE #cust
	SET 	territory_desc = t.territory_desc
	FROM #cust c, arterr t (NOLOCK)
	WHERE c.territory_code = t.territory_code

	UPDATE #cust
	SET 	salesperson_name = p.salesperson_name
	FROM #cust c, arsalesp p (NOLOCK)
	WHERE c.salesperson_code = p.salesperson_code

	UPDATE #cust
	SET status = status_code 
	FROM cc_cust_status_hist h (NOLOCK), #cust c
	WHERE clear_date IS NULL
	AND	h.customer_code = c.customer_code

	IF ( SELECT ISNUMERIC(db_date) FROM arcust c (NOLOCK), #cust t WHERE c.customer_code = t.customer_code ) <> 1
		SELECT @db_date = 0
	ELSE
		SELECT @db_date = db_date FROM arcust c (NOLOCK), #cust t WHERE c.customer_code = t.customer_code

	IF ( @db_date < 639907 )
		SELECT @db_date_str = 'N/A'
	ELSE
		SELECT @db_date_str = CONVERT(varchar(10),DATEADD(dd, @db_date - 639906, '01/01/1753'),101)

	IF @all_org_flag = 1
	BEGIN
		SELECT  @unposted = ISNULL(COUNT(1),0)
		FROM	arinpchg ar (NOLOCK)
		JOIN	#bg_data bg
		ON		ar.customer_code = bg.customer_code
	END
	ELSE
	BEGIN
		SELECT	@unposted = ISNULL(COUNT(*),0) 		
		FROM	arinpchg h (NOLOCK)
		JOIN	#bg_data bg
		ON		ar.customer_code = bg.customer_code
		AND		org_id BETWEEN @from_org AND @to_org

	END

	IF @all_org_flag = 1
	BEGIN
		SELECT  @unposted = @unposted + ISNULL(COUNT(1),0)
		FROM	arinppyt ar (NOLOCK)
		JOIN	#bg_data bg
		ON		ar.customer_code = bg.customer_code
	END
	ELSE
	BEGIN
		SELECT @unposted = @unposted + ISNULL(COUNT(*),0) 
		FROM arinppyt h (NOLOCK)		
		JOIN	#bg_data bg
		ON		ar.customer_code = bg.customer_code
		AND	org_id BETWEEN @from_org AND @to_org
	END


	IF @all_org_flag = 1
	BEGIN

		SELECT  @unposted = @unposted + ISNULL(COUNT(1),0)
		FROM	arinppdt ar (NOLOCK)
		JOIN	#bg_data bg
		ON		ar.customer_code = bg.customer_code
		WHERE	ar.trx_type IN ( 2141,2142,2151 )
	END
	ELSE
		SELECT @unposted = @unposted + ISNULL(COUNT(*),0) 
		FROM arinppdt d (NOLOCK)		
		JOIN	#bg_data bg
		ON		ar.customer_code = bg.customer_code
		WHERE	d.trx_type IN ( 2141,2142,2151 )
		AND		org_id BETWEEN @from_org AND @to_org

	IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('dbo.orders_all') )
	BEGIN

		-- WORKING TABLE
		DELETE #bg_data

		-- Call BG Data Proc
		EXEC cvo_bg_get_document_data_sp @cust_code, 2
	   
		CREATE TABLE #order_count(tablecount int)

		INSERT	#order_count
		SELECT	ISNULL(COUNT(1) ,0)
		FROM	#bg_data
		WHERE	parent = @cust_code

		SELECT  @orders = tablecount FROM #order_count
		DROP TABLE #order_count
	END
	ELSE
		SELECT @orders = -1


	SELECT @cust_code = customer_code FROM #cust

	SELECT	@open_orders = ISNULL(SUM(CASE WHEN type = 'I' THEN (a.gross_sales + a.total_tax - a.total_discount + a.freight) 
										ELSE ((a.gross_sales * -1) + (a.total_tax * -1) - (a.total_discount * -1) + (a.freight * -1)) END) , 0) 
	FROM	orders_all a (NOLOCK)
	JOIN	#bg_data b
	ON		CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)) = b.order_ctrl_num
	WHERE	a.status IN ( 'R', 'S', 'T' ) 
	AND		UPPER( a.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 ) 
	AND		a.void = 'N' 
	
	-- v2.1 Start
	SELECT	@open_orders2 = ISNULL(SUM
				(CASE WHEN type = 'I' THEN (a.total_amt_order + a.tot_ord_tax - a.tot_ord_disc + a.tot_ord_freight) 
					ELSE ((a.total_amt_order * -1) + (a.tot_ord_tax * -1) - (a.tot_ord_disc * -1) + (a.tot_ord_freight * -1)) END) , 0 ) 
	FROM	orders_all a (NOLOCK)
	JOIN	#bg_data b
	ON		CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)) = b.order_ctrl_num
	WHERE	a.status NOT IN ( 'R', 'S', 'T' ) 
	AND		UPPER( a.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 ) 
	AND		a.void = 'N' 
	-- v2.1 End


	SELECT @contacts = ISNULL(COUNT(*) ,0 )
	FROM cc_contacts a, #cust c 
	WHERE c.customer_code = a.customer_code
	
	SELECT @comments = ISNULL(COUNT(*) ,0 )
	FROM cc_comments a, #cust c 
	WHERE c.customer_code = a.customer_code
	AND	ISNULL(DATALENGTH(LTRIM(RTRIM(doc_ctrl_num))),0) = 0


	IF ( SELECT COUNT(*) FROM arnarel WHERE child = @cust_code ) > 0
		BEGIN
			SELECT 	@parent = parent,
							@parent_type = relation_code
			FROM arnarel (NOLOCK) WHERE child = @cust_code 	

			SELECT @parent_name = customer_name
			FROM arcust (NOLOCK)
			WHERE customer_code = @parent
		END
	ELSE IF ( SELECT COUNT(*) FROM arnarel (NOLOCK) WHERE parent = @cust_code ) > 0
		BEGIN
			SELECT 	@parent = parent,
							@parent_type = relation_code
			FROM arnarel (NOLOCK) WHERE parent = @cust_code 	

			SELECT @parent_name = customer_name
			FROM arcust (NOLOCK)
			WHERE customer_code = @parent
		END
	ELSE
		SELECT 	@parent = '',
						@parent_type = '',
						@parent_name = ''


	SELECT @price_class_desc = description
	FROM arprice p (NOLOCK), arcust c (NOLOCK)
	WHERE p.price_code = c.price_code
	AND customer_code = @cust_code




	IF ( SELECT ib_flag FROM glco ) = 0
		SELECT @all_org_flag = 1

	SELECT @date_entered = MAX( date_entered ) 
	FROM artrx (NOLOCK)
	WHERE customer_code = @cust_code
	AND trx_type = 2111
	AND void_flag = 0
	AND payment_type <> 3	

	SET ROWCOUNT 1

	SELECT @last_check = doc_ctrl_num,
					@last_amt = amt_net
	FROM artrx (NOLOCK)
	WHERE customer_code = @cust_code
	AND trx_type = 2111
	AND void_flag = 0
	AND payment_type <> 3	
	AND	date_entered = @date_entered
	ORDER BY trx_ctrl_num DESC

	SET ROWCOUNT 0


	SELECT 	customer_name, 
		c.city , 
		c.state, 
		c.postal_code,
		attention_name, 
		attention_phone, 
		terms_desc,
		'credit_limit' = STR(credit_limit,30,6), 
		c.phone_2, 
		c.customer_code,
		contact_name, 
		attention_phone, -- v2.2contact_phone,
		c.addr1, 
		c.addr2 , 
		c.addr3, 
		c.addr4, 
		c.addr5, 
		c.addr6, 
		tlx_twx, 
		c.phone_1, 
		c.country_code, 
		'',
		home_currency, 
		oper_currency,
		db_num, 
		'db date_str' = @db_date_str,
		db_credit_rating,
		nat_cur_code,
		status_type,
		check_credit_limit,
		territory_desc,
		salesperson_name,
		'unposted' = @unposted,
		'orders' = @orders,
		t.status,
		'contacts' = @contacts,
		'comments' = @comments,
		attention_email, -- v2.2 contact_email,
		url,
		'parent' = ISNULL(@parent,''),
		'parent_name' = ISNULL(@parent_name,''),
		'parent_type' = ISNULL(@parent_type,''),
		'price_code' = ISNULL(price_code,''),
		'price_class_desc' = ISNULL(@price_class_desc,''),
		'date_opened' = CASE WHEN date_opened > 639906 THEN CONVERT(varchar(12), DATEADD(dd, date_opened - 639906, '1/1/1753'),101) ELSE '' END,
		'addr_sort1' = ISNULL(addr_sort1,''),
		'credit_limit' = ISNULL(credit_limit,0),
		'open_orders' = ISNULL(@open_orders,0) + ISNULL(@open_orders2,0),
		'date_entered' = CASE WHEN @date_entered > 639906 THEN CONVERT(varchar(12), DATEADD(dd, @date_entered - 639906, '1/1/1753'),101) ELSE '' END,
		'last_check' = ISNULL(@last_check,0),
		'last_amt' = ISNULL(@last_amt,0)
	FROM arcust c, #cust t, glco
	WHERE c.customer_code = t.customer_code
	
SET NOCOUNT OFF
DROP TABLE #bg_data

GO
GRANT EXECUTE ON  [dbo].[cc_load_collections_sp] TO [public]
GO
