SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_print_statement_sp]	@customer_code 	varchar(8) = '',
					@credit_limit	varchar(40) = '',
					@balance	varchar(40) = '',
					@on_acct	varchar(40) = '',
					@bucket1	varchar(40) = '',
					@bucket2	varchar(40) = '',
					@bucket3	varchar(40) = '',
					@bucket4	varchar(40) = '',
					@bucket5	varchar(40) = '',
					@bucket6	varchar(40) = '',
					@balance_str	varchar(40) = '',
					@on_acct_str	varchar(40) = '',
					@bucket1_str	varchar(40) = '',
					@bucket2_str	varchar(40) = '',
					@bucket3_str	varchar(40) = '',
					@bucket4_str	varchar(40) = '',
					@bucket5_str	varchar(40) = '',
					@bucket6_str	varchar(40) = '',
					@attention_phone	varchar(40) = '',
					@print_company_info	varchar(3) = '0',
					@print_terms			varchar(3) = '0',
					@co_tel_no				varchar(40) = '',
					@co_fax_no				varchar(40) = '',
					@attention_name		varchar(40) = '',
					@db_num						varchar(8) = '',
					@all_org_flag			varchar(3) = '0',	 
					@from_org varchar(30) = '',
					@to_org varchar(30) = '',
					@display_org varchar(3) = '0',
					@user_name	varchar(30) = '',
					@company_db	varchar(30) = '',

					@bucket0	varchar(40) = '',
					@bucket0_str	varchar(40) = ''
					 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	

	DECLARE	@company_name	varchar(40),
				@co_addr1	varchar(40),
				@co_addr2	varchar(40),
				@co_addr3	varchar(40),
				@co_addr4	varchar(40),
				@co_addr5	varchar(40),
				@co_addr6	varchar(40),

		@customer_name	varchar(40),
		@addr1		varchar(40),
		@addr2		varchar(40),
		@addr3		varchar(40),
		@addr4		varchar(40),
		@addr5		varchar(40),
		@addr6		varchar(40),
		@terms		varchar(40)

	SET NOCOUNT ON

	CREATE TABLE #invoices
	(	doc_ctrl_num 		varchar(16)	NULL,
		date_doc 		int 		NULL,
		trx_type 		int 		NULL,
		amt_net 		float 		NULL,
		amt_paid_to_date	float 		NULL,
		balance 		float 		NULL,
		on_acct_flag 		smallint 	NULL,
		price_code 		varchar(8) 	NULL,
		territory_code 		varchar(8) 	NULL,
		nat_cur_code		varchar(8) 	NULL,
		trx_type_code		varchar(8) 	NULL,
		trx_ctrl_num		varchar(16) 	NULL,
		cust_po_num		varchar(20) 	NULL,
		date_due		int		NULL,
		symbol			varchar(8)	NULL,
		curr_precision		smallint	NULL,
		amt_on_acct		float		NULL,
		currency_mask		varchar(100)	NULL,
		org_id	varchar(30) NULL	)


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
		


	INSERT #invoices 
	(	doc_ctrl_num,
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
		org_id )
	SELECT	doc_ctrl_num,
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
		date_due,
		org_id
	FROM 	artrx 
	WHERE 	paid_flag = 0
	AND trx_type in (2021,2031)
	AND customer_code = @customer_code

	AND	void_flag = 0

	AND	doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )




	INSERT	#invoices
	(	
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
		amt_on_acct,
		org_id
	)
	SELECT 	h.doc_ctrl_num,
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
		h.amt_on_acct * -1,
		h.org_id
	FROM 	artrx h, artrxage a
	WHERE 	h.customer_code = @customer_code

	AND 	 	h.trx_type in (2111,2161)	
 	AND 	amt_on_acct > 0 
	AND 	h.paid_flag = 0
	AND 	ref_id = 0
	AND	h.trx_ctrl_num = a.trx_ctrl_num

	AND	h.void_flag = 0

	AND	h.customer_code = a.customer_code

	AND	h.doc_ctrl_num IN ( SELECT doc_ctrl_num FROM #non_zero_records )

IF @all_org_flag = '0'
	DELETE #invoices
	WHERE org_id NOT BETWEEN @from_org AND @to_org


	UPDATE 	#invoices
	SET 	#invoices.trx_type_code = artrxtyp.trx_type_code
	FROM 	#invoices,artrxtyp
	WHERE 	artrxtyp.trx_type = #invoices.trx_type

	UPDATE 	#invoices
	SET 	trx_type_code = 'CRMEMO'
	WHERE 	trx_type = 2161

	

	UPDATE 	#invoices
	SET			symbol = g.symbol,
					curr_precision = g.curr_precision,
					currency_mask = g.currency_mask
	FROM		#invoices t, glcurr_vw g
	WHERE		nat_cur_code = currency_code

	SELECT 	@company_name = 	company_name, 
					@co_addr1	= addr1,
					@co_addr2	= addr2,
					@co_addr3	= addr3,
					@co_addr4	= addr4,
					@co_addr5	= addr5,
					@co_addr6	= addr6
	FROM arco

	UPDATE 	#invoices
	SET			amt_net = ROUND(amt_net, curr_precision),
					amt_paid_to_date = ROUND(amt_paid_to_date, curr_precision),
					amt_on_acct = ROUND(amt_on_acct, curr_precision),
					balance = ROUND(balance, curr_precision)
		

SELECT	@customer_name = customer_name,

	@addr1	= addr1,
	@addr2	= addr2,
	@addr3	= addr3,
	@addr4	= addr4,
	@addr5	= addr5,
	@addr6	= addr6,
	@terms	= terms_desc

	FROM arcust, arterms
	WHERE customer_code = 	@customer_code
	AND arcust.terms_code = arterms.terms_code


	SELECT 	'CustCode' = @customer_code,
		'CustName' = @customer_name,
		'attName' = @attention_name,
		'phone' = @attention_phone,
		'addr1' = @addr1,
		'addr2' = @addr2,
		'addr3' = @addr3,
		'addr4' = @addr4,
		'addr5' = @addr5,
		'addr6' = @addr6,
		'terms' = @terms,
		'creditLimit' = @credit_limit,
		'age_balance' = @balance,
		'onAcct' = @on_acct,
		'b1' = @bucket1,
		'b2' = @bucket2,
		'b3' = @bucket3,
		'b4' = @bucket4,
		'b5' = @bucket5,
		'b6' = @bucket6,
		'balStr' = @balance_str,
		'onAcctStr' = @on_acct_str,
		'b1Str' = @bucket1_str,
		'b2Str' = @bucket2_str,
		'b3Str' = @bucket3_str,
		'b4Str' = @bucket4_str,
		'b5Str' = @bucket5_str,
		'b6Str' = @bucket6_str,
		'company' = @company_name,
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
		'CoAddr1' = @co_addr1,
		'CoAddr2' = @co_addr2,
		'CoAddr3' = @co_addr3,
		'CoAddr4' = @co_addr4,
		'CoAddr5' = @co_addr5,
		'CoAddr6' = @co_addr6,
		'PrintCompany' = @print_company_info,
		'PrintTerms' = @print_terms,
		'CoTel' = @co_tel_no,
		'CoFax' = @co_fax_no,
		'DbNum' = @db_num,
		'all_org_flag' = @all_org_flag,
		'from_org' = @from_org,
		'to_org' = @to_org,
		'display_org' = @display_org
	FROM 	#invoices 
	ORDER BY on_acct_flag DESC, date_doc, trx_ctrl_num 

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_print_statement_sp] TO [public]
GO
