SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[cc_inv_search_sp]	@doc_num varchar(16) = NULL

AS



	DECLARE @load_customer varchar(8),
					@detail_count	int,
					@last_doc varchar(16)


	CREATE table #invoices
	(	doc_ctrl_num varchar(16) NULL,
		check_num varchar(16) NULL,
		date_doc int NULL,
		date_due		int		NULL,
		status_code 		varchar(5) 	NULL,
		status_date 		int 		NULL,
		detail_count		int 		NULL,
		cust_po_num		varchar(20) 	NULL,
		trx_type int NULL,
		amt_net float NULL,
		amt_paid_to_date float NULL,
		balance float NULL,
		on_acct_flag smallint NULL,
		price_code varchar(8) NULL,
		territory_code varchar(8) NULL,
		nat_cur_code	varchar(8) NULL,
		apply_to_num varchar(16) NULL,
		sub_apply_num varchar(16) NULL,
		trx_type_code	varchar(8) NULL,
		trx_ctrl_num	varchar(16) NULL,
		customer_code	varchar(8) NULL,
		date_paid int NULL,
		payer_cust_code			varchar(8)	NULL,
		org_id varchar(30) NULL)


	INSERT #invoices
	SELECT doc_ctrl_num, 
	NULL,
	date_doc,
	date_due,
	'',
	0,
	0,
	cust_po_num,
	trx_type,
	amount,		
	amt_paid,
	NULL,
	0,	 
	price_code,
	territory_code,
	nat_cur_code,
	apply_to_num,
	sub_apply_num,	
	NULL,
	trx_ctrl_num,
	customer_code,
	date_paid,
	payer_cust_code,
	org_id
	FROM artrxage 
	WHERE doc_ctrl_num = @doc_num
		AND trx_type in (2021,2031)
		

	SELECT @load_customer = (SELECT min(customer_code) FROM #invoices WHERE customer_code is not null)





	UPDATE #invoices
	SET check_num = doc_ctrl_num,
	 doc_ctrl_num = apply_to_num
	WHERE doc_ctrl_num <> apply_to_num

	SELECT @last_doc = MIN(doc_ctrl_num) FROM #invoices WHERE trx_type IN ( 2021, 2031 )
	WHILE ( @last_doc IS NOT NULL )
		BEGIN
			SELECT @detail_count = count(*)
			FROM artrxpdt
			WHERE customer_code = @load_customer
			AND apply_to_num = @last_doc

			UPDATE 	#invoices 
			SET 	detail_count = @detail_count
			WHERE doc_ctrl_num = @last_doc

			SELECT @last_doc = MIN(doc_ctrl_num) 
			FROM #invoices 
			WHERE trx_type IN ( 2021, 2031 )
			AND doc_ctrl_num > @last_doc
		END


	UPDATE 	#invoices 
	SET 	cust_po_num = h.cust_po_num
	FROM 	#invoices i, artrx h
	WHERE 	i.doc_ctrl_num = h.doc_ctrl_num


	
INSERT #invoices
SELECT apply_to_num, 
	doc_ctrl_num, 
	date_doc,
	date_due,
	'',
	0,
	0,
	cust_po_num,
	trx_type,
	true_amount,
	amt_paid ,
	NULL,
	0,	
	price_code,
	territory_code,
	nat_cur_code,
	apply_to_num,
	sub_apply_num,	
	NULL,
	trx_ctrl_num,
	customer_code,
	date_paid,
	payer_cust_code,
	org_id
	FROM artrxage 
	WHERE apply_to_num in 
		(SELECT doc_ctrl_num FROM #invoices 
		WHERE trx_type in (2021,2031)) 
	AND trx_type in (2032,2111)	



	UPDATE #invoices
	SET trx_type = 2032 
	WHERE trx_type = 2111 
	AND check_num IN (SELECT doc_ctrl_num FROM artrxcdt WHERE trx_type = 2032) 



	INSERT #invoices
	SELECT 	apply_to_num, 
					doc_ctrl_num, 
					date_doc,
					date_due,
					'',
					0,
					0,
					'',
					trx_type,
					true_amount,
					amt_paid ,
					NULL,
					0,	
					price_code,
					territory_code,
					nat_cur_code,
					apply_to_num,
					sub_apply_num,	
					NULL,
					trx_ctrl_num,
					customer_code,
					date_paid,
					payer_cust_code,
					org_id
	FROM artrxage 
	WHERE apply_to_num IN (	SELECT doc_ctrl_num 
													FROM #invoices 
													WHERE trx_type IN (2021,2031))		
	AND trx_type IN (2061, 2071)

 	

	
	INSERT #invoices
	SELECT 	apply_to_num, 
					doc_ctrl_num,
					date_doc,
					date_due,
					'',
					0,
					0,
					'',
					trx_type,
					true_amount,
					amt_paid ,
					NULL,
					0,	
					price_code,
					territory_code,
					nat_cur_code,
					apply_to_num,
					sub_apply_num,	
					NULL,
					trx_ctrl_num,
					customer_code,
					date_paid,
					payer_cust_code,
					org_id
	FROM artrxage
	WHERE apply_to_num IN (	SELECT doc_ctrl_num 
													FROM #invoices 
													WHERE trx_type IN (2021,2031))		
	AND trx_type IN (2131,2141,2151)



	

	INSERT #invoices
	SELECT 	apply_to_num, 
					doc_ctrl_num,
					date_doc,
					date_due,
					'',
					0,
					0,
					'',
					trx_type,
					true_amount,
					amt_paid,
					NULL,
					0,	
					price_code,
					territory_code,
					nat_cur_code,
					apply_to_num,
					sub_apply_num,	
					NULL,
					trx_ctrl_num,
					customer_code,
					date_paid,
					payer_cust_code,
					org_id
	FROM artrxage
	WHERE apply_to_num IN (	SELECT doc_ctrl_num 
													FROM #invoices 
													WHERE trx_type IN (2021,2031)) 
	AND trx_type in (2112,2113,2121,2132,2142)	

			



	DELETE #invoices
	WHERE check_num in (SELECT doc_ctrl_num FROM artrxage WHERE apply_trx_type = 2031 AND trx_type = 2112)
	AND doc_ctrl_num = 'ON ACCT'




	UPDATE #invoices 
	SET balance = (	SELECT amt_on_acct * -1
									FROM artrx 
									WHERE trx_ctrl_num = #invoices.trx_ctrl_num
									AND trx_type = 2111) 
	WHERE #invoices.doc_ctrl_num = 'ON ACCT'

	UPDATE #invoices 
	SET balance = (	SELECT amt_on_acct
									FROM artrx 
									WHERE trx_ctrl_num = #invoices.trx_ctrl_num
									AND trx_type = 2113 ) 
	WHERE #invoices.doc_ctrl_num = 'ON ACCT'
	AND #invoices.amt_net > 0



	UPDATE #invoices
	SET balance = (	SELECT sum(true_amount) 
									FROM artrxage 
									WHERE apply_to_num = #invoices.doc_ctrl_num)
	FROM #invoices
	WHERE doc_ctrl_num <> 'ON ACCT'


	UPDATE #invoices
	SET #invoices.trx_type_code = artrxtyp.trx_type_code
	FROM #invoices,artrxtyp
	WHERE artrxtyp.trx_type = #invoices.trx_type


	UPDATE #invoices
	SET amt_paid_to_date = (amt_net-balance) * -1
	FROM #invoices
	WHERE sub_apply_num = doc_ctrl_num
	AND trx_type in (2021,2031)

	UPDATE 	#invoices 
	SET 	status_code = h.status_code,
				status_date = h.date
	FROM 	#invoices, cc_inv_status_hist h
	WHERE 	#invoices.doc_ctrl_num = h.doc_ctrl_num
	AND 	sequence_num = (SELECT MAX(sequence_num) 
												FROM cc_inv_status_hist 
												WHERE doc_ctrl_num = #invoices.doc_ctrl_num
												AND clear_date IS NULL)


	SELECT 	doc_ctrl_num,
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
					customer_code,
					@load_customer,
					date_due,
					status_code,
					status_date,
					detail_count,
					cust_po_num,
					(	SELECT count(*) 
						FROM cc_comments 
						WHERE ( doc_ctrl_num = #invoices.doc_ctrl_num OR doc_ctrl_num = #invoices.check_num)
						AND	customer_code = @load_customer ),
					( SELECT COUNT(*) 
						FROM comments 
						WHERE key_1 IN (SELECT trx_ctrl_num 
														FROM artrx 
														WHERE ( doc_ctrl_num = #invoices.doc_ctrl_num OR doc_ctrl_num = #invoices.check_num)
														AND	customer_code = @load_customer)),

					'days_open' = date_paid - date_doc,							
					date_paid,
					payer_cust_code,
					org_id
	FROM #invoices 
	ORDER BY on_acct_flag DESC, doc_ctrl_num DESC, sub_apply_num, trx_type, check_num

GO
GRANT EXECUTE ON  [dbo].[cc_inv_search_sp] TO [public]
GO
