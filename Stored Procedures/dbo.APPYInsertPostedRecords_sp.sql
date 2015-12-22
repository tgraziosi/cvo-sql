SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPYInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
										@date_applied int,
										@debug_level smallint = 0
AS
			 
	DECLARE	@current_date int,
			@year int,
			@month int,
			@thedate int,
			@result int


							 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "

EXEC @result = appdtjul_sp @year output, @month output, @thedate output, @date_applied 
IF (@result != 0)  
		RETURN 	-1
			 							 

	EXEC appdate_sp @current_date OUTPUT		


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "Insert on-acct aging records in #appyage_work"
	INSERT  #appyage_work (
			trx_ctrl_num,   trx_type,       	doc_ctrl_num,
			ref_id,         apply_to_num,   	apply_trx_type,
			date_doc,       date_applied,   	date_due,
			date_aging,     vendor_code,    	pay_to_code,
			class_code,     branch_code,    	amount,
			cash_acct_code,	nat_cur_code,		rate_home,
			rate_oper,		journal_ctrl_num,	account_code,
			org_id,		db_action )
	 SELECT	a.trx_ctrl_num, 	a.trx_type,			a.doc_ctrl_num,
	        0,			    	a.trx_ctrl_num,		0,
			a.date_doc,			a.date_applied,		0,
			0,					a.vendor_code,		a.pay_to_code,
			b.vend_class_code,	b.branch_code,		-a.amt_on_acct,
			a.cash_acct_code, 	a.nat_cur_code,		a.rate_home,
			a.rate_oper,		@journal_ctrl_num,	dbo.IBAcctMask_fn ( c.on_acct_code , a.org_id),
			a.org_id, 	2
	 FROM #appypyt_work a, apvend b, appymeth c
	 WHERE a.vendor_code = b.vendor_code
	 AND a.payment_code = c.payment_code
	 AND a.payment_type = 1
	 AND ((a.amt_on_acct) > (0.0) + 0.0000001)
	


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 102, 5 ) + " -- MSG: " + "Insert payment header records in #appytrx_work"
	INSERT  #appytrx_work (
		trx_ctrl_num,		trx_type,			doc_ctrl_num,
		batch_code,			date_applied,		date_doc,
		date_entered,		vendor_code,		pay_to_code,
		branch_code,    	class_code,			approval_code,
		cash_acct_code,		amt_discount,		amt_net,
		doc_desc,			user_id,			gl_trx_id,
		amt_on_acct,		payment_type,		payment_code,
		print_batch_num,	company_code,		nat_cur_code,
		rate_type_home,		rate_type_oper,		rate_home,
		rate_oper,		payee_name,		settlement_ctrl_num,
		org_id,			db_action)
	SELECT
		i.trx_ctrl_num,		i.trx_type,			i.doc_ctrl_num,
		i.batch_code,		i.date_applied,		i.date_doc,
		i.date_entered,		i.vendor_code,		i.pay_to_code,
		v.branch_code,		v.vend_class_code,	i.approval_code,
		i.cash_acct_code,	i.amt_disc_taken,	i.amt_payment,
		i.trx_desc,			i.user_id,			@journal_ctrl_num,
		i.amt_on_acct,		
		
			i.payment_type	+ SIGN(i.payment_type - 3) + 1,
												i.payment_code,
		i.print_batch_num,	i.company_code,		i.nat_cur_code,		
		i.rate_type_home,	i.rate_type_oper,   i.rate_home,		
		i.rate_oper,		payee_name,		settlement_ctrl_num,
		i.org_id,			2
	FROM    #appypyt_work i, apvend v 
	WHERE   i.vendor_code = v.vendor_code



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 135, 5 ) + " -- MSG: " + "Insert payment detail records in #appyxpdt_work"
INSERT  #appyxpdt_work (
	doc_ctrl_num,	trx_ctrl_num,		trx_type,
	sequence_id,	apply_to_num,		apply_trx_type,
	vendor_code,	date_apply_doc,		date_aging,
	amt_applied,	amt_disc_taken,		line_desc,
	vo_amt_applied,	vo_amt_disc_taken,	gain_home,
	gain_oper,	org_id,		db_action )
SELECT 	a.doc_ctrl_num,		a.trx_ctrl_num,			c.trx_type,
		a.sequence_id,		a.apply_to_num,			4091,
		b.vendor_code,		c.date_applied,			a.date_aging,
		a.amt_applied,		a.amt_disc_taken, 		a.line_desc,
	   	a.vo_amt_applied,	a.vo_amt_disc_taken,	a.gain_home,		
	   	a.gain_oper,		d.org_id, 		2	
FROM #paydist a, #appytrxv_work b, #appypyt_work c, #appypdt_work d
WHERE a.apply_to_num = b.trx_ctrl_num
AND a.doc_ctrl_num = c.doc_ctrl_num
AND a.cash_acct_code = c.cash_acct_code
AND d.trx_ctrl_num = c.trx_ctrl_num
AND d.trx_type = c.trx_type
AND a.apply_to_num = d.apply_to_num




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 160, 5 ) + " -- MSG: " + "Insert applied on_acct records in #appydsb_work"
INSERT #appydsb_work (
		check_ctrl_num,
		onacct_ctrl_num,
		trx_ctrl_num,
		doc_ctrl_num,
		sequence_id,
		apply_to_num,
		check_num,
		cash_acct_code,
		db_action
	   )
SELECT	"",
		"",
		trx_ctrl_num,
		doc_ctrl_num,
		sequence_id,
		apply_to_num,
		"",
		"",
		2
FROM    #paydist	    
WHERE payment_type IN (2,3)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 185, 5 ) + " -- MSG: " + "Insert applied on_acct payment records in #appyage_work"
INSERT  #appyage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		cash_acct_code,	nat_cur_code,		rate_home,
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,		db_action)									
SELECT	b.trx_ctrl_num, 	4171,      			a.doc_ctrl_num,
        0,					a.trx_ctrl_num,		b.trx_type + ((SIGN(b.payment_type - 3)+1)*50),
		b.date_doc,			b.date_applied, 	0,
		0,					b.vendor_code,		b.pay_to_code,
		c.vend_class_code,	c.branch_code,		b.amt_payment - b.amt_on_acct,
		a.cash_acct_code,	b.nat_cur_code,		b.rate_home,
		b.rate_oper,		@journal_ctrl_num,	dbo.IBAcctMask_fn ( d.on_acct_code , b.org_id),
		b.org_id, 	2
FROM #appytrxp_work a, #appypyt_work b, apvend c, appymeth d
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND a.cash_acct_code = b.cash_acct_code
AND b.vendor_code = c.vendor_code
AND b.payment_code = d.payment_code
AND b.payment_type = 2

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 210, 5 ) + " -- MSG: " + "Insert applied on_acct debit memo records in #appyage_work"
INSERT  #appyage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		cash_acct_code,	nat_cur_code,		rate_home,
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,		db_action)									
SELECT	b.trx_ctrl_num, 	4171,      			a.doc_ctrl_num,
        0,					a.trx_ctrl_num,		b.trx_type + ((SIGN(b.payment_type - 3)+1)*50),
		b.date_doc,			b.date_applied, 	0,
		0,					b.vendor_code,		b.pay_to_code,
		a.class_code,		a.branch_code,		b.amt_payment - b.amt_on_acct,
		a.cash_acct_code,	b.nat_cur_code,		b.rate_home,
		b.rate_oper,		@journal_ctrl_num,	dbo.IBAcctMask_fn ( d.dm_on_acct_code , b.org_id),
		b.org_id, 	2
FROM #appytrxp_work a, #appypyt_work b, apaccts d
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND a.cash_acct_code = b.cash_acct_code
AND a.posting_code = d.posting_code
AND b.payment_type = 3



 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 237, 5 ) + " -- MSG: " + "Insert applied payment records in #appyage_work"
INSERT  #appyage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		cash_acct_code,	nat_cur_code,		rate_home,
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,		db_action)									
SELECT	c.trx_ctrl_num,     c.trx_type + ((SIGN(a.payment_type - 3)+1)*50),      a.doc_ctrl_num,
        a.sequence_id,		a.apply_to_num,		4091,
		a.date_doc,			c.date_applied, 	b.date_due,
		a.date_aging,		b.vendor_code,		b.pay_to_code,
		b.class_code,		b.branch_code,		-a.vo_amt_applied,
		a.cash_acct_code,	b.nat_cur_code,		b.rate_home,
		b.rate_oper,		@journal_ctrl_num,	dbo.IBAcctMask_fn ( d.ap_acct_code , a.org_id),			 
		b.org_id, 	2
FROM #paydist a, #appytrxv_work b, #appypyt_work c, apaccts d, apco e
WHERE a.apply_to_num = b.trx_ctrl_num
AND ( (((a.amt_applied) > (0.0) + 0.0000001) and e.credit_invoice_flag = 0) or (e.credit_invoice_flag = 1))	
AND a.doc_ctrl_num = c.doc_ctrl_num
AND a.cash_acct_code = c.cash_acct_code
AND b.posting_code = d.posting_code


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 263, 5 ) + " -- MSG: " + "Insert applied discount records in #appyage_work"
INSERT  #appyage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		cash_acct_code,	nat_cur_code,		rate_home,
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,		db_action)									
SELECT	a.trx_ctrl_num,		4131,		    	a.doc_ctrl_num,
        a.sequence_id,		a.apply_to_num,		4091,
		a.date_doc,			c.date_applied, 	b.date_due,
		a.date_aging,		b.vendor_code,		b.pay_to_code,
		b.class_code,		b.branch_code,		-a.vo_amt_disc_taken,
		a.cash_acct_code,	b.nat_cur_code,		b.rate_home,
		b.rate_oper,		@journal_ctrl_num, 	dbo.IBAcctMask_fn ( d.ap_acct_code , c.org_id),
		b.org_id, 	2
FROM #paydist a, #appytrxv_work b, #appypyt_work c, apaccts d
WHERE a.apply_to_num = b.trx_ctrl_num
AND ((a.amt_disc_taken) > (0.0) + 0.0000001)
AND a.doc_ctrl_num = c.doc_ctrl_num
AND a.cash_acct_code = c.cash_acct_code
AND b.posting_code = d.posting_code



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyipr.cpp" + ", line " + STR( 290, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYInsertPostedRecords_sp] TO [public]
GO
