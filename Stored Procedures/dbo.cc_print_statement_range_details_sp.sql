SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_print_statement_range_details_sp]	@customer_code varchar(8),
																				@user_name	varchar(30) = '',
																				@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	
																							

	DECLARE @home_currency varchar(8)

	CREATE TABLE #invoices_details
	(	customer_code			varchar(8),
		doc_ctrl_num 			varchar(16)		NULL,
		date_doc 					int 					NULL,
		trx_type 					int 					NULL,
		amt_net 					float 				NULL,
		amt_paid_to_date	float 				NULL,
		balance 					float 				NULL,
		on_acct_flag 			smallint 			NULL,
		price_code 				varchar(8) 		NULL,
		territory_code 		varchar(8) 		NULL,
		nat_cur_code			varchar(8) 		NULL,
		trx_type_code			varchar(8) 		NULL,
		trx_ctrl_num			varchar(16) 	NULL,
		cust_po_num				varchar(20) 	NULL,
		date_due					int						NULL,
		symbol						varchar(8)		NULL,
		curr_precision		smallint			NULL,
		amt_on_acct				float					NULL,
		currency_mask			varchar(100)	NULL,
		)
		

	CREATE TABLE #non_zero_records
	(
		doc_ctrl_num 		varchar(16)	NULL, 
		trx_type 		smallint	NULL, 
		customer_code 		varchar(8)	NULL, 
		total 			float		NULL
	)

	INSERT #non_zero_records
	SELECT 	apply_to_num , 
					apply_trx_type, 
					customer_code, 
					SUM(amount) 
	FROM 		artrxage
	WHERE 	customer_code = @customer_code
	GROUP BY customer_code, apply_to_num, apply_trx_type
	HAVING ABS(SUM(amount)) > 0.0000001




	INSERT #invoices_details 
	(	customer_code,
		doc_ctrl_num,
		date_doc,
		trx_type,
		amt_net,
		amt_paid_to_date,
		balance,
		on_acct_flag,
		price_code,
		territory_code,
		nat_cur_code,
		trx_ctrl_num,
		cust_po_num,
		date_due
	)
	SELECT	customer_code,
					doc_ctrl_num,
					date_doc,
					trx_type,
					amt_net,
					amt_paid_to_date * -1,
					amt_net + ( amt_paid_to_date * - 1 ),
					0,
					price_code,
					territory_code,
					nat_cur_code,
					trx_ctrl_num,
					cust_po_num,
					date_due
	FROM 	artrx 
	WHERE 	paid_flag = 0
	AND trx_type in (2021,2031)
	AND customer_code = @customer_code

	AND	void_flag = 0

	AND	doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )




	INSERT	#invoices_details
	(	customer_code,
		doc_ctrl_num,
		date_doc,
		trx_type,
		amt_net,
		amt_paid_to_date,
		balance,
		on_acct_flag,
		price_code,
		territory_code,
		nat_cur_code,
		trx_ctrl_num,
		cust_po_num,
		date_due,
		amt_on_acct
	)
	SELECT 	h.customer_code,
					h.doc_ctrl_num,
					h.date_doc,
					a.trx_type,
					amt_net * - 1,
					amt_paid_to_date ,
					amt_on_acct * -1,
					1,
					h.price_code,
					h.territory_code,
					h.nat_cur_code,
					h.trx_ctrl_num,
					h.cust_po_num,
					h.date_due,
					h.amt_on_acct * -1
	FROM 	artrx h, artrxage a
	WHERE 	h.customer_code = 	@customer_code

	AND 	 	h.trx_type in (2111,2161)	
 	AND 	amt_on_acct > 0 
	AND 	h.paid_flag = 0
	AND 	ref_id = 0	AND	h.trx_ctrl_num = a.trx_ctrl_num

	AND	h.void_flag = 0

	AND	h.customer_code = a.customer_code

	AND	h.doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )




	UPDATE 	#invoices_details
	SET 		#invoices_details.trx_type_code = artrxtyp.trx_type_code
	FROM 		#invoices_details,artrxtyp
	WHERE 	artrxtyp.trx_type = #invoices_details.trx_type

	UPDATE 	#invoices_details
	SET 		trx_type_code = 'CRMEMO'
	WHERE 	trx_type = 2161

	

	UPDATE #invoices_details
	SET			symbol = g.symbol,
					curr_precision = g.curr_precision,
					currency_mask = g.currency_mask
	FROM		#invoices_details t, glcurr_vw g
	WHERE		nat_cur_code = currency_code


	UPDATE 	#invoices_details
	SET			amt_net = ROUND(amt_net, curr_precision),
					amt_paid_to_date = ROUND(amt_paid_to_date, curr_precision),
					amt_on_acct = ROUND(amt_on_acct, curr_precision),
					balance = ROUND(balance, curr_precision)
		

	SELECT 	'CustCode' = customer_code,
					doc_ctrl_num,
					'docdate' = case when date_doc > 639906 then convert(datetime, dateadd(dd, date_doc - 639906, '1/1/1753')) else date_doc end,
					trx_type, 
					amt_net,
					amt_paid_to_date,
					balance,
					amt_on_acct,
					price_code,
					territory_code,
					nat_cur_code,
					trx_type_code,
					cust_po_num,
					'duedate' = case when date_due > 639906 then convert(datetime, dateadd(dd, date_due - 639906, '1/1/1753')) else date_due end,
					symbol,
					curr_precision,
					currency_mask,
					'HomeCurr' = @home_currency
	FROM 	#invoices_details 
	ORDER BY customer_code, on_acct_flag DESC, trx_type_code, date_doc, trx_ctrl_num 


	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_print_statement_range_details_sp] TO [public]
GO
