SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_CR_on_acct_bg_sp]	@customer_code	varchar(10),
										@stmnt_date		int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @IsParent	int

	SET @IsParent = 0
	IF EXISTS (SELECT 1 FROM arnarel (NOLOCK) WHERE parent = @customer_code)
		SET @IsParent = 1

	-- Working Tables
	CREATE TABLE #removed_child (
		customer_code	varchar(10),
		remove_date		int)

	CREATE TABLE #joined_child (
		customer_code	varchar(10),
		start_date		int)

	-- v1.1 Start
	CREATE TABLE #joinremove_child (
		child			varchar(10),
		start_date		int,
		remove_date		int)
	-- v1.1 End

	-- Parent
	IF (@IsParent = 1)
	BEGIN
		-- Populate working tables
		INSERT	#removed_child (customer_code, remove_date)
		SELECT	DISTINCT child, end_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	parent = @customer_code
		AND		end_date_int <= @stmnt_date

		INSERT	#joined_child (customer_code, start_date)
		SELECT	DISTINCT child, start_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	parent = @customer_code
		AND		start_date_int <= @stmnt_date
		AND		start_date_int > 726468

		-- v1.1 Start
		INSERT	#removed_child (customer_code, remove_date)
		SELECT	DISTINCT a.child, a.end_date_int
		FROM	cvo_buying_groups_hist a (NOLOCK) 
		JOIN	artierrl b (NOLOCK)
		ON		a.child = b.rel_cust
		WHERE	b.parent = @customer_code
		AND		b.tier_level = 2
		AND		end_date_int <= DATEDIFF(DAY, '01/01/1900', GETDATE()) + 693596

		INSERT	#joined_child (customer_code, start_date)
		SELECT	DISTINCT a.child, a.start_date_int
		FROM	cvo_buying_groups_hist a (NOLOCK) 
		JOIN	artierrl b (NOLOCK)
		ON		a.child = b.rel_cust
		WHERE	b.parent = @customer_code
		AND		b.tier_level = 2
		AND		start_date_int <= DATEDIFF(DAY, '01/01/1900', GETDATE()) + 693596
		-- v1.1 End

		-- v1.1 Start
		INSERT	#joinremove_child (child, start_date, remove_date)
		SELECT	a.customer_code, a.start_date, b.remove_date
		FROM	#joined_child a
		JOIN	#removed_child b
		ON		a.customer_code = b.customer_code

		DELETE	a
		FROM	#joined_child a
		JOIN	#joinremove_child b
		ON		a.customer_code = b.child

		DELETE	a
		FROM	#removed_child a
		JOIN	#joinremove_child b
		ON		a.customer_code = b.child
		-- v1.1 End


		-- Insert into #tmpExclusions those transaction where the child has joined the parent but the transaction were prior to the joining
		INSERT	#tmpExc (trx)
		SELECT	a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	#joined_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 	
		AND		a.date_doc < b.start_date
		AND		a.doc_ctrl_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group > '')
	


		-- Insert into #tmpExclusions those transaction where RB credit return has been set not to affiliate with the buying group
		INSERT	#tmpExc (trx)
		SELECT	a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	artrx b (NOLOCK)
		ON		a.source_trx_ctrl_num = b.trx_ctrl_num
		JOIN	cvo_orders_all c (NOLOCK)
		ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
		JOIN	orders_all d (NOLOCK)
		ON		c.order_no = d.order_no
		AND		c.ext = d.ext
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 
		AND		b.trx_type = 2032	
		AND		ISNULL(c.buying_group,'') = ''
		AND		RIGHT(d.user_category,2) = 'RB'
		AND		a.customer_code IN (SELECT customer_code FROM #arvpay)


		-- Insert into #tmpinclude where a child has left the buying group but the transaction are prior to the child leaving
		INSERT	#tmpInc (doc_ctrl_num, one, date_doc, customer_code, nat_cur_code, amt_on_acct, date_on_acct, payment_code, cash_acct_code, payment_type, trx_ctrl_num)
		SELECT	a.doc_ctrl_num,
				1,
				a.date_doc,
				a.customer_code,
				a.nat_cur_code,
				a.amt_on_acct,
				a.date_applied,
				a.payment_code,
				a.cash_acct_code,
				a.payment_type,
				a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	#removed_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 	
		AND		a.date_doc <= b.remove_date
		AND		a.doc_ctrl_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = '')

		-- Insert into #tmpinclude those transaction where RB credit return has been set to affiliate with the buying group but is not a child
		INSERT	#tmpInc (doc_ctrl_num, one, date_doc, customer_code, nat_cur_code, amt_on_acct, date_on_acct, payment_code, cash_acct_code, payment_type, trx_ctrl_num)
		SELECT	a.doc_ctrl_num,
				1,
				a.date_doc,
				a.customer_code,
				a.nat_cur_code,
				a.amt_on_acct,
				a.date_applied,
				a.payment_code,
				a.cash_acct_code,
				a.payment_type,
				a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	artrx b (NOLOCK)
		ON		a.source_trx_ctrl_num = b.trx_ctrl_num
		JOIN	cvo_orders_all c (NOLOCK)
		ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
		JOIN	orders_all d (NOLOCK)
		ON		c.order_no = d.order_no
		AND		c.ext = d.ext
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 
		AND		b.trx_type = 2032	
		AND		ISNULL(c.buying_group,'') = @customer_code
		AND		RIGHT(d.user_category,2) = 'RB'
		AND		a.customer_code NOT IN (SELECT customer_code FROM #arvpay)

		-- v1.1 
		DELETE	a
		FROM	#tmpInc a
		JOIN	#joinremove_child b
		ON		a.customer_code = b.child
		WHERE	a.date_doc < b.start_date OR a.date_doc > b.remove_date
		-- v1.1 End

	END
	ELSE
	BEGIN
		-- Populate working tables
		INSERT	#removed_child (customer_code, remove_date)
		SELECT	DISTINCT child, end_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	child = @customer_code
		AND		end_date_int <= @stmnt_date

		INSERT	#joined_child (customer_code, start_date)
		SELECT	DISTINCT child, start_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	child = @customer_code
		AND		start_date_int <= @stmnt_date
		AND		start_date_int > 726468

		-- v1.1 Start
		INSERT	#joinremove_child (child, start_date, remove_date)
		SELECT	a.customer_code, a.start_date, b.remove_date
		FROM	#joined_child a
		JOIN	#removed_child b
		ON		a.customer_code = b.customer_code

		DELETE	a
		FROM	#joined_child a
		JOIN	#joinremove_child b
		ON		a.customer_code = b.child

		DELETE	a
		FROM	#removed_child a
		JOIN	#joinremove_child b
		ON		a.customer_code = b.child
		-- v1.1 End

		-- Insert into #tmpExclusions those transaction where the child has joined the parent but the transaction are after joining
		INSERT	#tmpExc (trx)
		SELECT	a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	#joined_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 	
		AND		a.date_doc >= b.start_date
		AND		a.doc_ctrl_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = '')	

		INSERT	#tmpExc (trx)
		SELECT	a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	#removed_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 	
		AND		a.date_doc <= b.remove_date
		AND		a.doc_ctrl_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = '')	

		-- Insert into #tmpExclusions those transaction where RB credit return has been set to affiliate with the buying group
		INSERT	#tmpExc (trx)
		SELECT	a.trx_ctrl_num
		FROM	artrx a (NOLOCK)
		JOIN	artrx b (NOLOCK)
		ON		a.source_trx_ctrl_num = b.trx_ctrl_num
		JOIN	cvo_orders_all c (NOLOCK)
		ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
		JOIN	orders_all d (NOLOCK)
		ON		c.order_no = d.order_no
		AND		c.ext = d.ext
		WHERE	a.non_ar_flag = 0 
		AND		a.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl (NOLOCK) WHERE ctrltype = 2 ) 
		AND		a.amt_on_acct > 0.0 
		AND		a.trx_type = 2111 
		AND		a.void_flag = 0 
		AND		b.trx_type = 2032	
		AND		ISNULL(c.buying_group,'') > ''
		AND		RIGHT(d.user_category,2) = 'RB'
		AND		a.customer_code = @customer_code

		-- v1.1 
		DELETE	a
		FROM	#tmpInc a
		JOIN	#joinremove_child b
		ON		a.customer_code = b.child
		WHERE	a.date_doc >= b.start_date AND a.date_doc <= b.remove_date
		-- v1.1 End


	END

	-- Run standard code but use custom #temp table
	SELECT	arinppyt.customer_code,
			arinppyt.doc_ctrl_num, 
			SUM(arinppdt.amt_applied) amt_applied 
	INTO	#input_totals_cvo 
	FROM	#arvpay, 
			arinppyt, 
			arinppdt 
	WHERE	#arvpay.customer_code = arinppyt.customer_code 
	AND		arinppyt.trx_ctrl_num = arinppdt.trx_ctrl_num 
	AND		arinppyt.trx_type = arinppdt.trx_type 
	AND		arinppyt.payment_type > 1 
	AND		arinppyt.trx_type = 2111 
	GROUP BY arinppyt.customer_code, arinppyt.doc_ctrl_num 

	SELECT	payment_code, 
			date_applied date_on_acct, 
			payment_type, 
			cash_acct_code,  
			artrx.doc_ctrl_num, 
			date_doc, 
			(amt_on_acct - ISNULL (amt_applied, 0.0)) amt_on_acct, 
			prompt1_inp, 
			prompt2_inp, 
			prompt3_inp, 
			prompt4_inp, 
			#arvpay.customer_code, 
			1 one, 
			artrx.nat_cur_code, 
			artrx.rate_type_home, 
			artrx.rate_home, 
			artrx.rate_type_oper, 
			artrx.rate_oper , 
			artrx.trx_ctrl_num 
	INTO	#onacct_list_cvo 
	FROM	artrx (NOLOCK) 	
	LEFT OUTER JOIN 
			#input_totals_cvo 
	ON		(artrx.customer_code = #input_totals_cvo.customer_code 					
	AND		artrx.doc_ctrl_num = #input_totals_cvo.doc_ctrl_num), 		
			#arvpay 
	WHERE	non_ar_flag = 0 
	AND		artrx.customer_code = #arvpay.customer_code 
	AND		artrx.doc_ctrl_num NOT IN ( SELECT ctrlnum FROM arstctrl WHERE ctrltype = 2 ) 
	AND		amt_on_acct > 0.0 
	AND		trx_type = 2111 
	AND		artrx.org_id = 'CVO' 
	AND		void_flag = 0 

	-- Create and populate the zoom table
	INSERT	#onacct_list_zoom
	SELECT	DISTINCT doc_ctrl_num, 
			one, 
			date_doc, 
			customer_code, 
			nat_cur_code, 
			amt_on_acct, 
			date_on_acct, 
			payment_code, 
			cash_acct_code, 
			payment_type, 
			trx_ctrl_num 
	FROM	#onacct_list_cvo 
	WHERE	amt_on_acct > 0.0 
	AND		trx_ctrl_num NOT IN (SELECT trx FROM #tmpExc) 
	UNION	
	SELECT	doc_ctrl_num, 
			one, 
			date_doc, 
			customer_code, 
			nat_cur_code, 
			amt_on_acct, 
			date_on_acct, 
			payment_code, 
			cash_acct_code, 
			payment_type, 
			trx_ctrl_num 
	FROM	#tmpInc 
	ORDER BY customer_code, date_doc, trx_ctrl_num

	-- Clean Up
	DROP TABLE #onacct_list_cvo
	DROP TABLE #removed_child
	DROP TABLE #joined_child
	DROP TABLE #tmpExc
	DROP TABLE #tmpInc

END
GO
GRANT EXECUTE ON  [dbo].[cvo_CR_on_acct_bg_sp] TO [public]
GO
