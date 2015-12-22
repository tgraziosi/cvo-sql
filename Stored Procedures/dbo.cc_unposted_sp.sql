SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_unposted_sp]	@customer_code 	varchar(8) = NULL,
																	@all_org_flag			smallint = 0,	 
																	@from_org varchar(30) = '',
																	@to_org varchar(30) = ''

AS
	DECLARE @curr_precision smallint,
			@IsParent int, -- v1.2
			@Parent varchar(8), -- v1.3
			@IsBG int -- v1.4
		

	SET NOCOUNT ON		

	IF ( SELECT ib_flag FROM glco ) = 0
		SELECT @all_org_flag = 1


	DECLARE @relation_code varchar(10)
	
	SELECT @relation_code = credit_check_rel_code
	FROM arco (NOLOCK)

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
	EXEC cvo_bg_get_document_data_sp @customer_code,1
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)

	INSERT #customers
	SELECT DISTINCT customer_code FROM #bg_data

	CREATE INDEX #customers_ind0 ON #customers(customer_code)



	CREATE TABLE #invoices
	(	trx_ctrl_num varchar(16)	DEFAULT '' NULL,
		doc_ctrl_num varchar(16)	DEFAULT '' NULL, 
		apply_to_num varchar(16)	DEFAULT '' NULL, 
		apply_trx_type smallint	DEFAULT 0 NULL, 
		trx_type smallint	DEFAULT 0 NULL, 
		date_doc int 		DEFAULT 0 NULL,
		customer_code varchar(8)	DEFAULT '' NULL, 
		ship_to_code varchar(8)	DEFAULT '' NULL, 
		territory_code varchar(8)	DEFAULT '' NULL, 
		cust_po_num varchar(20)	DEFAULT '' NULL, 
		salesperson_code varchar(8)	DEFAULT '' NULL, 
		amt_net		 float		DEFAULT 0 NULL, 
		amt_paid float		DEFAULT 0 NULL, 
		amt_due		 float		DEFAULT 0 NULL, 
		location_code varchar(8)	DEFAULT '' NULL, 
		amt_discount_taken float	DEFAULT 0 NULL, 
		amt_write_off_given float	DEFAULT 0 NULL, 
		nat_cur_code varchar(8)	DEFAULT '' NULL, 
		rate_type_home varchar(8)	DEFAULT '' NULL, 
		rate_type_oper varchar(8)	DEFAULT '' NULL, 
		rate_home float		DEFAULT 0 NULL, 
		rate_oper float		DEFAULT 0 NULL,
		on_acct_flag	 smallint	DEFAULT 0 NULL,
		trx_type_code	 varchar(8)	DEFAULT '' NULL,
		amt_on_acct	 float		DEFAULT 0 NULL,
		symbol	 	varchar(8)	DEFAULT '' NULL,
		curr_precision	 smallint	DEFAULT 0 NULL,
		salesperson_name	varchar(65) DEFAULT '' NULL,
		ship_to_name		varchar(65) DEFAULT '' NULL,
		void_type			smallint	DEFAULT 0 NULL,
		org_id				varchar(30) NULL
	)



	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		salesperson_code,
		ship_to_code,
		territory_code,
		cust_po_num,
		amt_net,
		amt_paid,
		amt_due,
		location_code,
		amt_discount_taken,
		amt_write_off_given,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		on_acct_flag,
		org_id	)
	SELECT	a.trx_ctrl_num,
		a.doc_ctrl_num,
		a.apply_to_num,
		a.apply_trx_type,
		a.trx_type,
		a.date_doc,
		a.customer_code,
		a.salesperson_code,
		a.ship_to_code,
		a.territory_code,
		a.cust_po_num,
		a.amt_net,
		a.amt_paid * -1,
		a.amt_due,
		a.location_code,
		a.amt_discount_taken,
		a.amt_write_off_given,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		a.org_id
	FROM	arinpchg a (NOLOCK)
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.trx_ctrl_num = b.doc_ctrl_num
	WHERE	a.trx_type in (2021,2031, 2998)

	

	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		salesperson_code,
		ship_to_code,
		territory_code,
		cust_po_num,
		amt_net,
		amt_paid,
		amt_due,
		location_code,
		amt_discount_taken,
		amt_write_off_given,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		on_acct_flag,
		org_id
	)
	SELECT	a.trx_ctrl_num,
		a.doc_ctrl_num,
		a.apply_to_num,
		a.apply_trx_type,
		a.trx_type,
		a.date_doc,
		a.customer_code,
		a.salesperson_code,
		a.ship_to_code,
		a.territory_code,
		a.cust_po_num,
		a.amt_net * -1,
		a.amt_paid,
		a.amt_due * -1,
		a.location_code,
		a.amt_discount_taken,
		a.amt_write_off_given,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		a.org_id
	FROM	arinpchg a (NOLOCK)
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.trx_ctrl_num = b.doc_ctrl_num
	WHERE	a.trx_type in (2032)
	AND		a.apply_trx_type = 2031




	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		salesperson_code,
		ship_to_code,
		territory_code,
		cust_po_num,
		amt_net,
		amt_paid,
		amt_due,
		location_code,
		amt_discount_taken,
		amt_write_off_given,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		on_acct_flag,
		org_id
	)
	SELECT	a.trx_ctrl_num,
		a.doc_ctrl_num,
		'ON ACCT',
		a.apply_trx_type,
		a.trx_type,
		a.date_doc,
		a.customer_code,
		a.salesperson_code,
		a.ship_to_code,
		a.territory_code,
		a.cust_po_num,
		a.amt_net * -1,
		a.amt_paid,
		a.amt_due * -1,
		a.location_code,
		a.amt_discount_taken,
		a.amt_write_off_given,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		1,
		a.org_id
	FROM	arinpchg a (NOLOCK)
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.trx_ctrl_num = b.doc_ctrl_num
	WHERE	a.trx_type in (2032)
	AND		a.apply_trx_type = 0



	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		amt_net,
		nat_cur_code,
		on_acct_flag,
		org_id
	)
	SELECT	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		amt_applied * -1,
		inv_cur_code,
		0,
		org_id
	FROM	arinppdt
	WHERE	trx_type = 2111
	AND customer_code IN ( SELECT customer_code FROM #customers )



	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		trx_type,
		date_doc,
		customer_code,
		amt_net,
		amt_on_acct,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		on_acct_flag,
		org_id
	)
	SELECT	trx_ctrl_num,
		doc_ctrl_num,
		'ON ACCT',
		trx_type,
		date_doc,
		customer_code,
		amt_payment * -1,
		amt_on_acct * -1,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		1,
		org_id
	FROM	arinppyt
	WHERE	trx_type = 2111
	AND customer_code IN ( SELECT customer_code FROM #customers )
	AND payment_type = 1
	AND on_acct_flag = 1



	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		amt_net,
		nat_cur_code,
		on_acct_flag,
		void_type,
		org_id
	)
	SELECT	d.trx_ctrl_num,
		d.doc_ctrl_num,
		d.apply_to_num,
		d.apply_trx_type,
		d.trx_type,
		d.date_doc,
		h.customer_code,
		d.amt_applied,
		d.inv_cur_code,
		0,
		h.void_type,
		h.org_id
	FROM	arinppdt d, arinppyt h
	WHERE	d.trx_type in ( 2111, 2112, 2113, 2121 )
	AND d.customer_code IN ( SELECT customer_code FROM #customers )
	AND d.customer_code = h.customer_code
	AND	d.trx_ctrl_num = h.trx_ctrl_num
	AND	h.amt_payment <> h.amt_on_acct



	INSERT #invoices 
	(	trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		apply_trx_type,
		trx_type,
		date_doc,
		customer_code,
		amt_net,
		amt_on_acct,
		nat_cur_code,
		on_acct_flag,
		void_type,
		org_id
	)
	SELECT	h.trx_ctrl_num,
		h.doc_ctrl_num,
		'',
		0,
		h.trx_type,
		h.date_doc,
		h.customer_code,
		h.amt_payment,
		h.amt_on_acct,
		h.nat_cur_code,
		0,
		h.void_type,
		h.org_id
	FROM	arinppyt h
	WHERE	h.trx_type in ( 2111, 2112, 2113, 2121 )
	AND		h.posted_flag = 0 -- v1.1
	AND 	h.customer_code IN ( SELECT customer_code FROM #customers )
	AND	h.amt_payment = h.amt_on_acct
	

	UPDATE #invoices
	SET	symbol = g.symbol,
		curr_precision = g.curr_precision,
		@curr_precision = g.curr_precision
	FROM	#invoices t, glcurr_vw g
	WHERE	nat_cur_code = currency_code


	UPDATE 	#invoices
	SET 	#invoices.trx_type_code = artrxtyp.trx_type_code
	FROM 	#invoices,artrxtyp
	WHERE 	artrxtyp.trx_type = #invoices.trx_type

	UPDATE 	#invoices
	SET 	trx_type_code = 'PROFORMA'
	WHERE 	trx_type = 2998

	UPDATE 	#invoices
	SET 	trx_type_code = 'NSF'
	WHERE 	trx_type = 2121
	AND		void_type = 1
	
	UPDATE 	#invoices
	SET 	trx_type_code = 'VOID CR'
	WHERE 	trx_type = 2121
	AND		void_type = 2
	
	UPDATE 	#invoices
	SET 	trx_type_code = 'VOID ICR'
	WHERE 	trx_type = 2121
	AND		void_type = 3



	UPDATE 	#invoices
	SET 	salesperson_name = p.salesperson_name
	FROM 	#invoices t,arsalesp p
	WHERE 	t.salesperson_code = p.salesperson_code	 


	UPDATE 	#invoices
	SET 	ship_to_name = s.ship_to_name
	FROM 	#invoices t, arshipto s
	WHERE	t.customer_code = s.customer_code
	AND	t.ship_to_code = s.ship_to_code


	IF @all_org_flag = 0
		DELETE #invoices
		WHERE org_id NOT BETWEEN @from_org AND @to_org

	SELECT 	trx_type_code,
		trx_ctrl_num,
		doc_ctrl_num,
		apply_to_num,
		case when date_doc > 639906 then convert(datetime, dateadd(dd, date_doc - 639906, '1/1/1753')) else date_doc end,
		nat_cur_code,
		STR(amt_net,30,@curr_precision), 
		STR(amt_paid,30,@curr_precision), 
		STR(amt_on_acct,30,@curr_precision), 
		ship_to_code,
		territory_code,
		cust_po_num,
		salesperson_code,
		trx_type,
		STR(amt_due,30,@curr_precision), 
		location_code,
		symbol,
		curr_precision,
		salesperson_name,
		ship_to_name,
		org_id,
		customer_code
	FROM 	#invoices 
	ORDER BY trx_type, trx_ctrl_num, date_doc
	
	SET NOCOUNT OFF
	DROP TABLE #bg_data
GO
GRANT EXECUTE ON  [dbo].[cc_unposted_sp] TO [public]
GO
