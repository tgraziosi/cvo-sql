SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_inv_hist_cursor_sp] 	@customer_code 	varchar(8) = NULL,
																				@allow_open			int	= 0,
																				@num_days				int = 0,
																				@num_trx				int = 0,
																				@sort_by 				tinyint = 1,
																				@sort_type 			tinyint = 1,
																				@all_org_flag			smallint = 0,	 
																				@from_org varchar(30) = 'CVO',
																				@to_org varchar(30) = 'CVO'


AS

	SET NOCOUNT ON

	DECLARE	@detail_count	int,
					@last_doc varchar(16),
					@order varchar(255),
					@num_days_str varchar(15),
					@trx_ctrl_num varchar(16),
					@detail int,
					@cc_comments int,
					@comments int,
					@last_cust varchar(8)


	DECLARE @relation_code varchar(10)
	
	SELECT @relation_code = credit_check_rel_code
	FROM arco (NOLOCK)

	CREATE TABLE #customers( customer_code varchar(8) )

	INSERT #customers
	SELECT @customer_code


	IF ( SELECT COUNT(*) FROM arnarel WHERE parent IN ( SELECT customer_code FROM #customers ) AND relation_code = @relation_code) > 0 
	 INSERT #customers 
	 SELECT child 
	 FROM arnarel 
	 WHERE parent IN ( SELECT customer_code FROM #customers ) 
	 AND relation_code = @relation_code









	SELECT	* INTO		#artrxage 		FROM		artrxage 		WHERE customer_code IN ( SELECT customer_code FROM #customers )
	SELECT	* INTO		#artrx 		FROM		artrx 		WHERE customer_code IN ( SELECT customer_code FROM #customers )


	CREATE INDEX ih_idx_1 ON #artrxage( customer_code, doc_ctrl_num, trx_type )
	CREATE INDEX ih_idx_2 ON #artrx( customer_code, doc_ctrl_num, trx_type )


	CREATE TABLE #invoices
	(	apply_to_num 		varchar(16) NULL,
		apply_trx_type 				int 				NULL,
		customer_code	varchar(8) NULL,
		amount float NULL)

	SELECT @num_days_str = CONVERT( varchar(15), @num_days )


	IF ( @sort_by = 1 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.date_doc,  sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 1 AND @sort_type = 2 )
		SELECT @order = 'ORDER BY  h.date_doc DESC,  sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 2 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.doc_ctrl_num, sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 2 AND @sort_type = 2 )
		SELECT @order = ' ORDER BY  h.doc_ctrl_num DESC, sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 3 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.cust_po_num, h.doc_ctrl_num, sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 3 AND @sort_type = 2 ) 
		SELECT @order = ' ORDER BY  h.cust_po_num DESC, h.doc_ctrl_num DESC, sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 4 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.customer_code, h.doc_ctrl_num, sub_apply_num, ABS(h.trx_type - 2021)'
	IF ( @sort_by = 4 AND @sort_type = 2 ) 
		SELECT @order = ' ORDER BY  h.customer_code DESC, h.doc_ctrl_num DESC, sub_apply_num, ABS(h.trx_type - 2021)'
 
	IF ( @num_trx > 0 )
		BEGIN
			SET ROWCOUNT @num_trx
				BEGIN
					IF @num_days > 0
						INSERT #invoices
						SELECT 	apply_to_num , 
										apply_trx_type, 
										customer_code,
										SUM(amount) 
										FROM 	#artrxage
										WHERE 	customer_code IN ( SELECT customer_code FROM #customers )
										AND 	date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days
										GROUP BY customer_code,apply_to_num, apply_trx_type
					ELSE
						INSERT #invoices
						SELECT 	apply_to_num , 
										apply_trx_type, 
										customer_code,
										SUM(amount) 
										FROM 	#artrxage
										WHERE 	customer_code IN ( SELECT customer_code FROM #customers )
										GROUP BY customer_code,apply_to_num, apply_trx_type
				END	
			SET ROWCOUNT 0
		END
	ELSE
		IF @num_days > 0
			BEGIN
				INSERT #invoices
				SELECT 	apply_to_num , 
								apply_trx_type, 
								customer_code,
								SUM(amount) 
								FROM 	#artrxage
								WHERE 	customer_code IN ( SELECT customer_code FROM #customers )
								AND 	date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days
								GROUP BY customer_code,apply_to_num, apply_trx_type
			END
		ELSE
			BEGIN
				INSERT #invoices
				SELECT 	apply_to_num , 
								apply_trx_type, 
								customer_code,
								SUM(amount) 
								FROM 	#artrxage
								WHERE 	customer_code IN ( SELECT customer_code FROM #customers )
								GROUP BY customer_code,apply_to_num, apply_trx_type
			END

	IF @allow_open = 0
		EXEC(	"	INSERT #final
						(	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							amt_net,
							amt_paid_to_date,
							balance,
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
							cc_comment_count,
							comment_count,
							date_paid,
							days_open,
							payer_cust_code,
							detail_count,
							sort_date,
							paid_flag,
							org_id )
					SELECT	h.doc_ctrl_num,
									'',
									h.date_doc,
									h.trx_type,
									amt_net,
									amt_paid_to_date,
									amt_net - amt_paid_to_date,
									h.price_code,
									h.territory_code,
									h.nat_cur_code,
									i.apply_to_num,
									trx_type_code,
									0,
									'',
									h.date_due,
									h.trx_ctrl_num,
									h.cust_po_num,
									'',
									'',
									h.order_ctrl_num,
									0,
									0,
									h.date_paid,
									h.date_paid - h.date_doc,							
									payer_cust_code,
									'',
									h.date_doc,
									h.paid_flag,
									g.org_id
					FROM 		#invoices i, #artrx h, #artrxage g, artrxtyp t 
					WHERE i.apply_to_num = g.doc_ctrl_num
					AND 	g.trx_ctrl_num = h.trx_ctrl_num
					AND		g.trx_type = t.trx_type
					AND		i.customer_code = h.customer_code
					AND 	h.trx_type IN ( 2021,2031)						
					AND 	g.ref_id = 1
					AND 	h.paid_flag = 1 " + @order )
	ELSE
		EXEC(	"	INSERT #final
						(	doc_ctrl_num,
							check_num,
							date_doc,
							trx_type,
							amt_net,
							amt_paid_to_date,
							balance,
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
							cc_comment_count,
							comment_count,
							date_paid,
							days_open,
							payer_cust_code,
							detail_count,
							sort_date,
							paid_flag )
					SELECT	h.doc_ctrl_num,
									'',
									h.date_doc,
									h.trx_type,
									amt_net,
									amt_paid_to_date,
									amt_net - amt_paid_to_date,
									h.price_code,
									h.territory_code,
									h.nat_cur_code,
									i.apply_to_num,
									trx_type_code,
									0,
									'',
									h.date_due,
									h.trx_ctrl_num,
									h.cust_po_num,
									'',
									'',
									h.order_ctrl_num,
									0,
									0,
									h.date_paid,
									h.date_paid - h.date_doc,							
									payer_cust_code,
									'',
									h.date_doc,
									h.paid_flag
					FROM 		#invoices i, #artrx h, #artrxage g, artrxtyp t 
					WHERE i.apply_to_num = g.doc_ctrl_num
					AND 	g.trx_ctrl_num = h.trx_ctrl_num
					AND		i.customer_code = h.customer_code
					AND 	h.trx_type IN ( 2021,2031)
					AND 	g.ref_id = 1
					AND		g.trx_type = t.trx_type " + @order )

	CREATE INDEX #final_idx1 ON #final( doc_ctrl_num, trx_ctrl_num )


	IF @allow_open = 1
		BEGIN	
			SELECT	customer_code,
							doc_ctrl_num, 
							'true_amount' = SUM(true_amount)
			INTO #cm 
			FROM 	#artrxage 
			WHERE 	paid_flag = 0
			AND trx_type in (2111,2161)
			AND customer_code IN ( SELECT customer_code FROM #customers )
			AND	ref_id < 1
			AND apply_to_num NOT IN ( SELECT doc_ctrl_num FROM #final )
			GROUP BY doc_ctrl_num
			HAVING ABS(SUM(true_amount)) > 0.0001 
		
			INSERT #final
								(	doc_ctrl_num,
									check_num,
									date_doc,
									trx_type,
									amt_net,
									amt_paid_to_date,
									balance,
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
									cc_comment_count,
									comment_count,
									date_paid,
									days_open,
									payer_cust_code,
									detail_count,
									sort_date,
									paid_flag,
									org_id )
			SELECT 	"ON ACCT", 
				a.doc_ctrl_num,
				date_doc,
				a.trx_type,
				a.true_amount,
				amt_paid,
				NULL,
				price_code,
				territory_code,
				nat_cur_code,
				apply_to_num,
				trx_type_code,
				1,
				sub_apply_num,	
				NULL,
				trx_ctrl_num,
				NULL,
				NULL,
				NULL,
				order_ctrl_num,
				0,	
				0,
				0,
				0,
				payer_cust_code,
				0,
				date_doc,
				paid_flag,
				org_id
			FROM 	#artrxage a, #cm c, artrxtyp t
			WHERE 	a.customer_code = c.customer_code
			AND 	a.trx_type in (2111,2161)	
		 	AND 	(amount > 0.000001 or amount < -0.000001 )
			AND 	a.apply_to_num = a.doc_ctrl_num
			AND 	paid_flag = 0
			AND 	ref_id = 0
			AND		a.doc_ctrl_num = c.doc_ctrl_num
			AND		ISNULL(DATALENGTH(RTRIM(LTRIM(c.doc_ctrl_num))), 0 ) > 0
			AND		a.trx_type = t.trx_type
		
			DROP TABLE #cm
		END

	IF @all_org_flag = 0
		DELETE #invoices 
		WHERE	org_id NOT BETWEEN @from_org AND @to_org



	DELETE 	#final
	WHERE 	check_num in (SELECT	a.doc_ctrl_num 
												FROM 	#artrxage a, #final f
												WHERE 	a.apply_trx_type = 2031 
												AND 	a.trx_type = 2112
												AND 	a.customer_code = f.payer_cust_code)
	AND doc_ctrl_num = "ON ACCT"
	AND trx_type NOT IN ( 2161, 2111)



	UPDATE	#final 
	SET 	balance = (	SELECT 	SUM(a.amount)
										FROM 	#artrxage a, #final f
										WHERE 	a.doc_ctrl_num = f.check_num
										AND 	a.customer_code = f.payer_cust_code
										AND 	a.ref_id < 1 )
	WHERE 	#final.doc_ctrl_num = 'ON ACCT'




	SELECT @last_cust = MIN(payer_cust_code) FROM #final
	WHILE ( @last_cust IS NOT NULL )
		BEGIN
			SELECT @last_doc = MIN(doc_ctrl_num) 
			FROM #final 
			WHERE 	doc_ctrl_num <> 'ON ACCT'
			AND payer_cust_code = @last_cust

			WHILE ( @last_doc IS NOT NULL )
				BEGIN
					SELECT @detail = 	COUNT(a.doc_ctrl_num)	
					FROM #artrxage a, #final f	
					WHERE a.customer_code = @last_cust
					AND f.doc_ctrl_num = a.apply_to_num
					AND a.doc_ctrl_num <> a.apply_to_num
					--AND a.trx_type > 2031
					AND f.doc_ctrl_num = @last_doc
					AND ref_id > 0
		
		
					SELECT @cc_comments = COUNT(*) 
					FROM cc_comments
					WHERE doc_ctrl_num = @last_doc
					AND	customer_code = @last_cust
		
					SELECT @comments = COUNT(*) 
					FROM comments
					WHERE key_1 IN ( SELECT trx_ctrl_num 
					FROM #final 
					WHERE doc_ctrl_num = @last_doc
					AND payer_cust_code = @last_cust )
		
					UPDATE #final
					SET detail_count = @detail,
							cc_comment_count = @cc_comments,
							comment_count = @comments
					WHERE doc_ctrl_num = @last_doc
					AND payer_cust_code = @last_cust
		
					UPDATE #final
					SET balance = ( SELECT SUM(amount) FROM #artrxage 
					WHERE apply_to_num = @last_doc
					AND payer_cust_code = @last_cust )
		
					SELECT @last_doc = MIN(doc_ctrl_num) 
					FROM #final 
					WHERE doc_ctrl_num > @last_doc 
					AND doc_ctrl_num <> 'ON ACCT'
					AND payer_cust_code = @last_cust
				END
			SELECT @last_cust = MIN(payer_cust_code) 
			FROM #final
			WHERE payer_cust_code > @last_cust
		END




















SET ROWCOUNT 0

SET NOCOUNT OFF

DROP TABLE #invoices

GO
GRANT EXECUTE ON  [dbo].[cc_inv_hist_cursor_sp] TO [public]
GO
