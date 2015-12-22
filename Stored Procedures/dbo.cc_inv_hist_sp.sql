SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[cc_inv_hist_sp] @customer_code 	varchar(8) = NULL,
										@allow_open			int	= -1,
										@num_days				int = 365,
										@num_trx				int = 50,
										@sort_by 				tinyint = 1,
										@sort_type 			tinyint = 1,
										@all_org_flag			smallint = 0,	 
										@from_org varchar(30) = 'CVO',
										@to_org varchar(30) = 'CVO'

AS

	SET NOCOUNT ON

	DECLARE	@detail_count	int,
					@last_doc varchar(16),
					@last_cust varchar(8)



	DECLARE @relation_code varchar(10),
			@IsParent int, -- v1.2   
			@Parent varchar(8), -- v1.3
			@IsBG int -- v1.4

	SELECT @relation_code = credit_check_rel_code
	FROM arco (NOLOCK)

	IF ( SELECT ib_flag FROM glco ) = 0
		SELECT @all_org_flag = 1


	CREATE TABLE #customers( customer_code varchar(8) )

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
	EXEC cvo_bg_get_document_data_sp @customer_code
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)

	INSERT #customers
	SELECT DISTINCT customer_code FROM #bg_data

    CREATE INDEX #customers_ind1 ON #customers(customer_code) 

	SELECT a.* INTO  #artrx   
	FROM	artrx a(NOLOCK) 
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.doc_ctrl_num = b.doc_ctrl_num


	SELECT a.* INTO  #artrxage   
	FROM	artrxage a (NOLOCK) 
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.doc_ctrl_num = b.doc_ctrl_num


	CREATE TABLE #invoices
	(	doc_ctrl_num			varchar(16) NULL,
		check_num 				varchar(16) NULL,
		date_doc 					int 				NULL,
		trx_type 					int 				NULL,
		amt_net 					float 			NULL,
		amt_paid_to_date	float 			NULL,
		balance 					float 			NULL,
		on_acct_flag 			smallint 		NULL,
		price_code 				varchar(8) 	NULL,
		territory_code 		varchar(8) 	NULL,
		nat_cur_code			varchar(8) 	NULL,
		apply_to_num 		varchar(16) NULL,
		sub_apply_num 		varchar(16) NULL,
		trx_type_code			varchar(8) 	NULL,
		trx_ctrl_num			varchar(16) NULL,
		paid_flag					smallint 		NULL,
		date_due 					int 				NULL,
		sort_date 				int 				NULL,
		cust_po_num				varchar(20)	NULL,
		inv_from					datetime 		NULL,
		inv_to						datetime 		NULL,
		order_ctrl_num 		varchar(16) NULL,
		date_paid					int 				NULL,
		days_open					int 				NULL,
		customer_code			varchar(8)	NULL,
		payer_cust_code			varchar(8)	NULL,
		detail_count		int 		NULL DEFAULT 0,
		org_id	varchar(30) NULL )


		IF @num_days > 0
			INSERT #invoices (customer_code,doc_ctrl_num, amt_net, amt_paid_to_date)
			SELECT	customer_code,
					doc_ctrl_num, 
					SUM(amount),		
					SUM(amt_paid)
			FROM 	#artrxage 
			WHERE 	date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days
			AND		trx_type in (2021,2031)
			GROUP BY customer_code, doc_ctrl_num
		ELSE
			INSERT #invoices (customer_code,doc_ctrl_num, amt_net, amt_paid_to_date)
			SELECT	customer_code,
					doc_ctrl_num, 
					SUM(amount),		
					SUM(amt_paid)
			FROM 	#artrxage 
			WHERE 	trx_type in (2021,2031)
			GROUP BY customer_code, doc_ctrl_num


		UPDATE 	#invoices
		SET 	date_doc = a.date_doc,
				date_due = a.date_due,
				trx_type = a.trx_type,
				price_code = a.price_code,
				territory_code = a.territory_code,
				nat_cur_code = a.nat_cur_code,
				apply_to_num = a.apply_to_num,
				sub_apply_num = a.sub_apply_num,	
				trx_ctrl_num = a.trx_ctrl_num,
				paid_flag = a.paid_flag,
				on_acct_flag = 0,
				sort_date = a.date_doc,
				cust_po_num = a.cust_po_num,
				order_ctrl_num = a.order_ctrl_num,
				date_paid = a.date_paid,		
				days_open = a.date_paid - a.date_doc,							
				customer_code = a.customer_code, 
				payer_cust_code = a.payer_cust_code,
				org_id = a.org_id
		FROM 	#artrxage a, #invoices i
		WHERE 	a.doc_ctrl_num = i.doc_ctrl_num
		AND 	a.customer_code = i.customer_code
		AND a.trx_type in(2031,2021)		

	IF @allow_open = 0
		DELETE #invoices WHERE paid_flag = 0
		
	DELETE	#invoices
	WHERE 	doc_ctrl_num <> apply_to_num


	SELECT @last_cust = MIN(customer_code) FROM #invoices
	WHILE ( @last_cust IS NOT NULL )
	BEGIN
		SELECT @last_doc = MIN(doc_ctrl_num) 
		FROM #invoices 
		WHERE trx_type IN ( 2021, 2031 )
		AND customer_code = @last_cust

		WHILE ( @last_doc IS NOT NULL )
			BEGIN
				SELECT @detail_count = count(*)
				FROM artrxage (NOLOCK)
				WHERE customer_code = @last_cust
				AND apply_to_num = @last_doc
				AND doc_ctrl_num <> @last_doc
	
				UPDATE 	#invoices 
				SET 	detail_count = @detail_count
				WHERE doc_ctrl_num = @last_doc
				AND customer_code = @last_cust
	
				SELECT @last_doc = MIN(doc_ctrl_num) 
				FROM #invoices 
				WHERE trx_type IN ( 2021, 2031 )
				AND doc_ctrl_num > @last_doc
				AND customer_code = @last_cust
			END

		SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust
	END

	SELECT	a.customer_code,
			a.doc_ctrl_num, 
			'true_amount' = SUM(a.true_amount)
	INTO	#cm 
	FROM 	#artrxage a
	WHERE 	a.paid_flag = 0
	AND		a.trx_type in (2111,2161)
	AND		a.ref_id < 1
	GROUP BY a.customer_code, a.doc_ctrl_num
	HAVING ABS(SUM(a.true_amount)) > 0.0001 


	IF @num_days > 0 
		INSERT 	#invoices(	doc_ctrl_num,	check_num,		date_doc,	trx_type,	amt_net,	amt_paid_to_date,		balance, 	on_acct_flag,	price_code,		territory_code,		nat_cur_code,		apply_to_num,		sub_apply_num,		trx_type_code,		trx_ctrl_num,		paid_flag,		date_due,		sort_date,		cust_po_num,		inv_from,		inv_to,		order_ctrl_num,		date_paid,		days_open,		customer_code,		payer_cust_code, org_id )
		SELECT							'ON ACCT', 		a.doc_ctrl_num,	date_doc,	trx_type,	amount,		amt_paid ,					NULL,			1,						price_code,		territory_code,		nat_cur_code,		apply_to_num,		sub_apply_num,		NULL,							trx_ctrl_num,		paid_flag,		date_due,		0,						cust_po_num,		NULL,				NULL,			order_ctrl_num,		NULL,					NULL,					a.customer_code,	payer_cust_code, org_id
		FROM 	#artrxage a, #cm c
		WHERE 	a.customer_code = c.customer_code
		AND 	trx_type in (2111,2161)	
		AND 	(amount > 0.0001 or amount < -0.0001 )
		AND 	a.apply_to_num = a.doc_ctrl_num
		AND 	paid_flag = 0
		AND 	ref_id = 0
		AND		a.doc_ctrl_num = c.doc_ctrl_num
		AND		ISNULL(DATALENGTH(RTRIM(LTRIM(c.doc_ctrl_num))), 0 ) > 0
		AND 		date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days
	ELSE
		INSERT 	#invoices(	doc_ctrl_num,	check_num,		date_doc,	trx_type,	amt_net,	amt_paid_to_date,		balance, 	on_acct_flag,	price_code,		territory_code,		nat_cur_code,		apply_to_num,		sub_apply_num,		trx_type_code,		trx_ctrl_num,		paid_flag,		date_due,		sort_date,		cust_po_num,		inv_from,		inv_to,		order_ctrl_num,		date_paid,		days_open,		customer_code,		payer_cust_code, org_id )
		SELECT 							'ON ACCT', 		a.doc_ctrl_num,	date_doc,	trx_type,	amount,		amt_paid ,					NULL,			1,						price_code,		territory_code,		nat_cur_code,		apply_to_num,		sub_apply_num,		NULL,							trx_ctrl_num,		paid_flag,		date_due,		0,						cust_po_num,		NULL,				NULL,			order_ctrl_num,		NULL,					NULL,					a.customer_code,		payer_cust_code, org_id
		FROM 	#artrxage a, #cm c
		WHERE 	a.customer_code = c.customer_code
		AND 	trx_type in (2111,2161)	
		AND 	(amount > 0.0001 or amount < -0.0001 )
		AND 	a.apply_to_num = a.doc_ctrl_num
		AND 	paid_flag = 0
		AND 	ref_id = 0
		AND		a.doc_ctrl_num = c.doc_ctrl_num
		AND		ISNULL(DATALENGTH(RTRIM(LTRIM(c.doc_ctrl_num))), 0 ) > 0
	
	
	DROP TABLE #cm


	IF @all_org_flag = 0
		DELETE #invoices 
		WHERE	org_id NOT BETWEEN @from_org AND @to_org

	DELETE #invoices
	WHERE check_num IN (SELECT 	doc_ctrl_num 
						FROM 	#artrxage 
						WHERE 	apply_trx_type = 2031 
						AND 	trx_type = 2112)
	AND doc_ctrl_num = 'ON ACCT'
	AND trx_type NOT IN ( 2161, 2111)


	DELETE #invoices 
	WHERE check_num IN (SELECT	a.doc_ctrl_num 
						FROM 		#artrx a, #invoices i 
						WHERE 	void_flag = 1 
						AND 		a.customer_code = i.customer_code
						AND 		a.payment_type <> 1 ) 
	AND trx_type IN (2111,2161)

	UPDATE	#invoices 
	SET		balance = a.amt_on_acct * -1
	FROM 	#artrx a, #invoices i 
	WHERE 	a.trx_ctrl_num = i.trx_ctrl_num
	AND 	a.customer_code = i.customer_code
	AND 	a.trx_type = 2111
	AND		i.doc_ctrl_num = 'ON ACCT'

	UPDATE	#invoices 
	SET		balance = a.amt_on_acct
	FROM	#artrx a, #invoices i 
	WHERE	a.trx_ctrl_num = i.trx_ctrl_num
	AND 	a.customer_code = i.customer_code
	AND		a.trx_type = 2113 
	AND		i.doc_ctrl_num = 'ON ACCT'
	AND		i.amt_net > 0


	SELECT @last_cust = MIN(customer_code) FROM #invoices
	WHILE ( @last_cust IS NOT NULL )
	BEGIN
		SELECT @last_doc = MIN(doc_ctrl_num) 
		FROM #invoices 
		WHERE customer_code = @last_cust

		WHILE ( @last_doc IS NOT NULL )
		BEGIN
			UPDATE #invoices
			SET balance = ( SELECT SUM(a.amount)
							FROM 		#artrxage a, #invoices i 
							WHERE 	a.customer_code = i.customer_code
							AND			a.customer_code = @last_cust
							AND			a.apply_to_num = @last_doc
							AND 		a.apply_to_num = i.doc_ctrl_num )
				
			WHERE on_acct_flag = 0
			AND			customer_code = @last_cust
			AND			apply_to_num = @last_doc

			UPDATE #invoices
			SET sort_date = (	SELECT DISTINCT a.date_doc 
								FROM	#artrx a, #invoices i 
								WHERE	a.customer_code = i.customer_code
								AND		a.doc_ctrl_num = i.doc_ctrl_num
								AND			a.customer_code = @last_cust
								AND			a.doc_ctrl_num = @last_doc
								AND a.trx_type IN (2031,2021))
			FROM #invoices
			WHERE on_acct_flag = 0
			AND sort_date IS NULL
			AND		customer_code = @last_cust
			AND		doc_ctrl_num = @last_doc

			SELECT @last_doc = MIN(doc_ctrl_num) 
			FROM #invoices 
			WHERE customer_code = @last_cust
			AND		doc_ctrl_num > @last_doc
		END
		SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust
	END

	UPDATE	#invoices
	SET			#invoices.trx_type_code = artrxtyp.trx_type_code
	FROM 		#invoices, artrxtyp
	WHERE 	artrxtyp.trx_type = #invoices.trx_type

	UPDATE	#invoices
	SET			amt_paid_to_date = (amt_net-balance) * -1
	FROM		#invoices
	WHERE		sub_apply_num = doc_ctrl_num
	AND			trx_type IN (2021,2031)

	DELETE FROM #invoices
	WHERE balance = 0
	AND doc_ctrl_num = 'ON ACCT'

	CREATE TABLE #results
	(	doc_ctrl_num			varchar(16)	NULL,
		check_num					varchar(16) NULL,
		date_doc					int 				NULL,
		trx_type					int 				NULL,
		amt_net						float 			NULL,
		amt_paid_to_date	float 			NULL,
		balance						float 			NULL,
		on_acct_flag			smallint 		NULL,
		price_code				varchar(8) 	NULL,
		territory_code		varchar(8) 	NULL,
		nat_cur_code			varchar(8) 	NULL,
		apply_to_num			varchar(16) NULL,
		sub_apply_num			varchar(16) NULL,
		trx_type_code			varchar(8) 	NULL,
		trx_ctrl_num			varchar(16) NULL,
		paid_flag					smallint		NULL,
		date_due					int 				NULL,
		sort_date					int 				NULL,

		cust_po_num				varchar(20)	NULL,
		inv_from					datetime 		NULL,
		inv_to						datetime 		NULL,
		order_ctrl_num		varchar(16) NULL,

		date_paid					int 				NULL,
		days_open					int 				NULL,
		customer_code			varchar(8)	NULL,
		payer_cust_code			varchar(8)	NULL,
		detail_count		int 		NULL DEFAULT 0,
		org_id varchar(30) NULL )

	CREATE TABLE	#toprint ( doc_ctrl_num varchar(16))

	SET ROWCOUNT @num_trx

	INSERT 	#toprint			
	SELECT 	DISTINCT doc_ctrl_num 
	FROM 		#invoices 
	WHERE 	doc_ctrl_num = 'ON ACCT'

	INSERT	#toprint			
	SELECT	DISTINCT doc_ctrl_num 
	FROM 		#invoices 
	WHERE on_acct_flag = 0
	
	SET ROWCOUNT 0

	INSERT	#results			
	SELECT 	* 
	FROM 		#invoices
	WHERE 	doc_ctrl_num IN (SELECT doc_ctrl_num FROM #toprint)

	IF (@sort_by = 1)
		IF (@sort_type = 1)
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
												FROM 	#artrx a
												WHERE	( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
												AND		a.customer_code = #results.customer_code )),
							date_paid,
							days_open,
							payer_cust_code,
							detail_count,
							org_id							
			FROM 		#results 
			ORDER BY on_acct_flag DESC, sort_date, customer_code, sub_apply_num, ABS(trx_type - 2021), check_num
		ELSE
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
												FROM 		#artrx a
												WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
												AND			a.customer_code = #results.customer_code )),
							date_paid,
							days_open,
							payer_cust_code,
							detail_count,
							org_id
			FROM #results 
			ORDER BY on_acct_flag DESC, sort_date DESC, customer_code, sub_apply_num, ABS(trx_type - 2021), check_num

	IF (@sort_by = 2)
		IF (@sort_type = 1)
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
								FROM 		#artrx a
								WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND			a.customer_code = #results.customer_code )),
						date_paid,
						days_open,
						payer_cust_code,
						detail_count,
						org_id
			FROM #results 
			ORDER BY on_acct_flag DESC, doc_ctrl_num, customer_code, sub_apply_num, ABS(trx_type - 2021), check_num
		ELSE
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
								FROM 		#artrx a
								WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND			a.customer_code = #results.customer_code )),
						date_paid,
						days_open,
						payer_cust_code,
						detail_count,
						org_id
		FROM #results 
			ORDER BY on_acct_flag DESC, doc_ctrl_num DESC, customer_code, sub_apply_num, ABS(trx_type - 2021), check_num
	
	IF (@sort_by = 3)
		IF (@sort_type = 1)
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
								FROM 		#artrx a
								WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND			a.customer_code = #results.customer_code )),
						date_paid,
						days_open,
						payer_cust_code,
						detail_count,
						org_id
			FROM #results 
			ORDER BY on_acct_flag DESC, cust_po_num, customer_code, doc_ctrl_num, sub_apply_num, ABS(trx_type - 2021), check_num
		ELSE
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
								FROM 		#artrx a
								WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND			a.customer_code = #results.customer_code )),
						date_paid,
						days_open,
						payer_cust_code,
						detail_count,
						org_id
			FROM #results 
			ORDER BY on_acct_flag DESC, cust_po_num DESC, customer_code, doc_ctrl_num, sub_apply_num, ABS(trx_type - 2021), check_num

	IF (@sort_by = 4)
		IF (@sort_type = 1)
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
								FROM 		#artrx a
								WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND			a.customer_code = #results.customer_code )),
							date_paid,
							days_open,
							payer_cust_code,
							detail_count,
							org_id							
			FROM 		#results 
			ORDER BY on_acct_flag DESC, customer_code, sort_date, sub_apply_num, ABS(trx_type - 2021), check_num
		ELSE
			SELECT	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							STR(amt_net,30,6), 
							STR(amt_paid_to_date,30,6), 
							STR(balance,30,6), 
							price_code,
							territory_code,
							nat_cur_code,
							apply_to_num,
							trx_type_code,
							on_acct_flag,
							sub_apply_num,
							date_due,
							trx_ctrl_num,
							cust_po_num,
							inv_from,
							inv_to,
							order_ctrl_num,

							(	SELECT count(*) 
								FROM cc_comments c
								WHERE ( c.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND	c.customer_code = #results.customer_code ),
							( SELECT COUNT(*) 
								FROM comments 
								WHERE key_1 IN (SELECT 	a.trx_ctrl_num 
								FROM 		#artrx a
								WHERE ( a.doc_ctrl_num = #results.doc_ctrl_num OR doc_ctrl_num = #results.check_num)
								AND			a.customer_code = #results.customer_code )),
							date_paid,
							days_open,
							payer_cust_code,
							detail_count,
							org_id
			FROM #results 
			ORDER BY on_acct_flag DESC, customer_code DESC, sort_date, sub_apply_num, ABS(trx_type - 2021), check_num

	DROP TABLE #artrxage
	DROP TABLE #artrx


	DROP TABLE #invoices
	DROP TABLE #toprint
	DROP TABLE #results
	DROP TABLE #bg_data

GO
GRANT EXECUTE ON  [dbo].[cc_inv_hist_sp] TO [public]
GO
