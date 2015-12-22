SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_pymt_hist_cursor_sp]	@customer_code 	varchar(8) = NULL,
																	@all_org_flag			smallint = 0,	 
																	@from_org varchar(30) = '',
																	@to_org varchar(30) = '',
																	@sort_by 				tinyint = 2,
																	@sort_type 			tinyint = 2

AS
	SET NOCOUNT ON

	DECLARE @trx_ctrl_num	varchar(16),
					@doc_ctrl_num varchar(16),
					@last_doc varchar(16),
					@on_acct 			float,
					@amt_net			float ,
					@row 					int,
					@detail_count	int,
					@order varchar(255),
					@detail int,
					@cc_comments int,
					@comments int,
					@last_cust varchar(8)


	DECLARE @relation_code varchar(10)
	
	SELECT @relation_code = credit_check_rel_code
	FROM arco (NOLOCK)

	CREATE TABLE #payments
	(	trx_ctrl_num 			varchar(16) NULL,
		doc_ctrl_num 			varchar(16) NULL,
		date_doc 					int NULL,
		trx_type 					int NULL,
		amt_net 					float NULL,
		amt_paid_to_date 	float NULL,
		balance 					float NULL,
		customer_code 		varchar(12) NULL,
		void_flag 				smallint NULL,
		trx_type_code 		varchar(8) NULL,
		payment_type 			smallint NULL,
		nat_cur_code			varchar(8) NULL,
		date_sort					int,
		date_applied			int NULL,
		price_code				varchar(8) NULL,
		amt_on_acct				float NULL,
		sequence_id				int NULL,
		org_id	varchar(30) NULL )


	CREATE table #results
	(		customer_code	varchar(8),
			trx_ctrl_num 		varchar(16) NULL		)

	CREATE TABLE #customers( customer_code varchar(8) )

	INSERT #customers
	SELECT @customer_code


	CREATE TABLE #pmt_final
	(	trx_ctrl_num 			varchar(16) NULL,
		doc_ctrl_num 			varchar(16) NULL,
		date_doc 					int NULL,
		trx_type 					int NULL,
		amt_net 					float NULL,
		amt_paid_to_date 	float NULL,
		balance 					float NULL,
		customer_code 		varchar(12) NULL,
		void_flag 				smallint NULL,
		trx_type_code 		varchar(8) NULL,
		payment_type 			smallint NULL,
		nat_cur_code			varchar(8) NULL,
		date_sort					int,
		date_applied			int NULL,
		price_code				varchar(8) NULL,
		cc_comments_count	int NULL,
		comments_count		int NULL,
		detail_count int NULL,
		sort_date 				int 				NULL,
		org_id	varchar(30) NULL )


	IF ( SELECT COUNT(*) FROM arnarel WHERE parent IN ( SELECT customer_code FROM #customers ) AND relation_code = @relation_code) > 0 
	 INSERT #customers 
	 SELECT child 
	 FROM arnarel 
	 WHERE parent IN ( SELECT customer_code FROM #customers ) 
	 AND relation_code = @relation_code









	SELECT	* INTO #artrx FROM artrx WHERE customer_code IN ( SELECT customer_code FROM #customers )

	CREATE INDEX ph_idx_1 ON #artrx( customer_code, doc_ctrl_num, trx_type )



	IF ( @sort_by = 1 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.date_doc,  h.doc_ctrl_num'
	IF ( @sort_by = 1 AND @sort_type = 2 )
		SELECT @order = 'ORDER BY  h.date_doc DESC,  h.doc_ctrl_num'
	IF ( @sort_by = 2 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.doc_ctrl_num, h.date_doc'
	IF ( @sort_by = 2 AND @sort_type = 2 )
		SELECT @order = ' ORDER BY  h.doc_ctrl_num DESC, h.date_doc'
	IF ( @sort_by = 3 AND @sort_type = 1 )
		SELECT @order = ' ORDER BY  h.customer_code, h.date_doc,  h.doc_ctrl_num'
	IF ( @sort_by = 3 AND @sort_type = 2 )
		SELECT @order = 'ORDER BY  h.customer_code DESC, h.date_doc,  h.doc_ctrl_num'



	INSERT #payments
	SELECT 	trx_ctrl_num, 
					doc_ctrl_num,
					date_doc,
					trx_type,
					amt_net,
					null,
					amt_on_acct,
					customer_code,
					void_flag,
					NULL,
					payment_type,
					nat_cur_code,
					date_doc,
					date_applied,
					price_code,
					amt_on_acct,
					0,
					org_id
		FROM #artrx 
		WHERE trx_type = 2111
		AND customer_code IN ( SELECT customer_code FROM #customers )
		AND payment_type = 1

CREATE INDEX payments_idx_1 ON #payments( customer_code, doc_ctrl_num, payment_type )
CREATE INDEX payments_idx_2 ON #payments( customer_code, doc_ctrl_num, trx_type )
CREATE INDEX payments_idx_3 ON #payments( customer_code, doc_ctrl_num, trx_ctrl_num )


	SELECT @last_cust = MIN(customer_code) FROM #payments
	WHILE ( @last_cust IS NOT NULL )
		BEGIN
			SELECT @doc_ctrl_num = MIN(doc_ctrl_num) 
			FROM #payments 
			WHERE payment_type <> 3
			AND customer_code = @last_cust

			WHILE (@doc_ctrl_num IS NOT NULL)
				BEGIN
					IF (	SELECT COUNT(*) 
							FROM #payments 
							WHERE doc_ctrl_num = @doc_ctrl_num
							AND customer_code = @last_cust
							AND	payment_type = 2 ) > 0
						BEGIN
							SELECT 	@on_acct = amt_on_acct,
											@amt_net = amt_net
							FROM #payments
							WHERE doc_ctrl_num = @doc_ctrl_num
							AND customer_code = @last_cust
							AND	payment_type = 1 
					
							UPDATE #payments
							SET balance = @on_acct,
									amt_net = @amt_net
							WHERE doc_ctrl_num = @doc_ctrl_num
							AND customer_code = @last_cust
							AND	payment_type = 2 
				
							DELETE #payments
							WHERE doc_ctrl_num = @doc_ctrl_num
							AND customer_code = @last_cust
							AND	payment_type = 1
						END
			
					SELECT @doc_ctrl_num = MIN(doc_ctrl_num) 
					FROM #payments
					WHERE doc_ctrl_num > @doc_ctrl_num
				
					AND payment_type <> 3
					AND customer_code = @last_cust
				END	
			SELECT @last_cust = MIN(customer_code) 
			FROM #payments
			WHERE customer_code > @last_cust
		END




	INSERT #payments
	SELECT	p.trx_ctrl_num, 
					a.doc_ctrl_num,
					a.date_doc,
					a.trx_type,
					a.amt_net * -1,
					NULL,
					a.amt_on_acct * -1,
					a.customer_code,
					a.void_flag,
					NULL,
					a.payment_type,
					a.nat_cur_code,
					p.date_doc,
					p.date_applied,
					a.price_code,
					a.amt_on_acct,
					0,
					a.org_id
	FROM #payments p, artrx a 
	WHERE a.trx_type in (2112, 2113, 2121)
	AND a.customer_code = p.customer_code
	AND a.doc_ctrl_num = p.doc_ctrl_num 



	UPDATE #payments
	SET 	doc_ctrl_num = 'VOID ICR',
				trx_type = 9999
	WHERE trx_type = 2112

	UPDATE #payments
	SET 	doc_ctrl_num = 'VOID CR',
				trx_type = 9999
	WHERE trx_type = 2113

	UPDATE #payments
	SET 	doc_ctrl_num = 'NSF',
				trx_type = 9999
	WHERE trx_type = 2121

	UPDATE #payments
	SET 	doc_ctrl_num = 'VOID WR',
				trx_type = 9999
	WHERE trx_type = 2142



	UPDATE #payments 
	SET date_sort = b.date_doc
	FROM #payments , #payments b
	WHERE #payments.trx_ctrl_num = b.trx_ctrl_num
	AND #payments.trx_type = 9999
	AND b.trx_type = 2111
	AND	#payments.sequence_id = b.sequence_id



	UPDATE #payments
	SET #payments.trx_type_code = artrxtyp.trx_type_code
	FROM #payments,artrxtyp
	WHERE artrxtyp.trx_type = #payments.trx_type


	DELETE FROM #payments WHERE payment_type = 3

	UPDATE #payments SET trx_type = 9999 WHERE trx_type is null


	INSERT #results
	SELECT customer_code, trx_ctrl_num FROM #payments WHERE trx_type = 2111 ORDER BY date_doc DESC 
	SET ROWCOUNT 0

	EXEC(	'	INSERT #pmt_final
					(	trx_ctrl_num,
						doc_ctrl_num,
						date_doc,
						trx_type,
						amt_net,
						amt_paid_to_date,
						balance,
						customer_code,
						void_flag,
						trx_type_code,
						payment_type,
						nat_cur_code,
						date_sort,
						date_applied,
						price_code,
						sort_date,
						org_id		)
					SELECT 	h.trx_ctrl_num,
									doc_ctrl_num,
									date_doc,
									trx_type,
									"amt_net" = STR(amt_net,30,6), 
									"amt_paid_to_date" = STR(amt_paid_to_date,30,6), 
									"balance" = STR(balance,30,6), 
									h.customer_code,
									void_flag,
									trx_type_code,
									payment_type,
									nat_cur_code,
									date_sort,
									date_applied,
									price_code,
									date_doc,
									h.org_id	
					FROM 	#payments h, #results r
					WHERE 	h.trx_ctrl_num = r.trx_ctrl_num 
					AND h.customer_code = r.customer_code ' + @order )


	SELECT @last_cust = MIN(customer_code) FROM #pmt_final
	WHILE ( @last_cust IS NOT NULL )
		BEGIN
			SELECT @last_doc = MIN(doc_ctrl_num) 
			FROM #pmt_final 
			WHERE customer_code = @last_cust
		
			WHILE ( @last_doc IS NOT NULL )
				BEGIN







					SELECT @detail = 	COUNT(apply_to_num)	
					FROM artrxage
					WHERE customer_code = @last_cust
					AND doc_ctrl_num <> apply_to_num
					AND apply_trx_type < 2111
					AND doc_ctrl_num = @doc_ctrl_num
		
					SELECT @cc_comments = COUNT(*) 
					FROM cc_comments
					WHERE doc_ctrl_num = @last_doc
					AND customer_code = @last_cust
		
					SELECT @comments = COUNT(*) 
					FROM comments
					WHERE key_1 IN ( SELECT trx_ctrl_num 
														FROM #pmt_final 
														WHERE doc_ctrl_num = @last_doc
														AND customer_code = @last_cust )
		
					UPDATE #pmt_final
					SET detail_count = @detail,
							cc_comments_count = @cc_comments,
							comments_count = @comments
					WHERE doc_ctrl_num = @last_doc
					AND customer_code = @last_cust
		
					SELECT @last_doc = 
					MIN(doc_ctrl_num) 
					FROM #pmt_final 
					WHERE doc_ctrl_num > @last_doc
					AND customer_code = @last_cust
				END
			SELECT @last_cust = MIN(customer_code) 
			FROM #pmt_final
			WHERE customer_code > @last_cust
		END


DROP TABLE #payments
DROP TABLE #results

SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_pymt_hist_cursor_sp] TO [public]
GO
