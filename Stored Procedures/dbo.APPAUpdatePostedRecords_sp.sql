SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPAUpdatePostedRecords_sp]  @journal_ctrl_num varchar(16),
										@debug_level smallint = 0
AS


							 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appaupr.cpp' + ', line ' + STR( 52, 5 ) + ' -- ENTRY: '




UPDATE #appadsb_work
SET check_num = '',
    cash_acct_code = '',
	db_action = #appadsb_work.db_action | 1
FROM #appadsb_work, #appapyt_work b
WHERE #appadsb_work.check_num = b.doc_ctrl_num
AND #appadsb_work.cash_acct_code = b.cash_acct_code
AND b.void_type IN (1,2,3,5)

IF (@@error != 0)
	   RETURN -1






UPDATE  #appaxage_work
SET     paid_flag = 1,
		db_action = #appaxage_work.db_action | 1
FROM 	#appaxage_work, #appapyt_work b
WHERE   #appaxage_work.doc_ctrl_num = b.doc_ctrl_num
AND   #appaxage_work.cash_acct_code = b.cash_acct_code
AND   #appaxage_work.apply_trx_type = 0
AND   b.void_type IN (1,2,3,5)

UPDATE  #appaxage_work
SET     date_paid = b.date_applied,
		db_action = #appaxage_work.db_action | 1
FROM 	#appaxage_work, #appapyt_work b
WHERE   #appaxage_work.doc_ctrl_num = b.doc_ctrl_num
AND   #appaxage_work.cash_acct_code = b.cash_acct_code
AND   #appaxage_work.apply_trx_type = 0
AND   b.void_type IN (1,2,3,5)
AND   b.date_applied > #appaxage_work.date_paid









UPDATE #appapyt_work
SET db_action = 1
FROM #appapyt_work, #appaxage_work b
WHERE #appapyt_work.doc_ctrl_num = b.doc_ctrl_num
AND #appapyt_work.cash_acct_code = b.cash_acct_code
AND b.apply_trx_type = 0
AND #appapyt_work.void_type = 4





UPDATE  #appaxage_work
SET     paid_flag = 0,
		db_action = #appaxage_work.db_action | 1
FROM 	#appaxage_work, #appapyt_work b
WHERE   #appaxage_work.doc_ctrl_num = b.doc_ctrl_num
AND   #appaxage_work.cash_acct_code = b.cash_acct_code
AND   #appaxage_work.apply_trx_type = 0
AND   b.void_type = 4
AND   b.db_action = 1


IF(@@error != 0)
		RETURN -1




INSERT  #appaxage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		paid_flag,      cash_acct_code, 	amt_paid_to_date,
		date_paid,		nat_cur_code,		rate_home,		
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,			db_action )				
SELECT  b.trx_ctrl_num, b.trx_type,  		b.doc_ctrl_num,     
		0,              b.trx_ctrl_num,     0,
		b.date_doc,     b.date_applied,    	0,
		0,              b.vendor_code,  	b.pay_to_code,
		b.class_code,   b.branch_code,  	-b.amt_payment,   
		0,              dbo.IBAcctMask_fn(b.cash_acct_code, a.org_id),   0,
		0,				a.nat_cur_code, 	a.rate_home,
		a.rate_oper,	@journal_ctrl_num,	dbo.IBAcctMask_fn(c.on_acct_code, a.org_id),
		a.org_id,		2 								
FROM    #appapyt_work a, #appatrxp_work b, appymeth c
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND		a.payment_code = c.payment_code
AND     a.db_action = 0
AND     a.void_type = 4


IF(@@error != 0)
		RETURN -1







INSERT  #appaxage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		paid_flag,      cash_acct_code, 	amt_paid_to_date,
		date_paid,		nat_cur_code,		rate_home,		
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,			db_action )				
SELECT  a.trx_ctrl_num, 4181,		  	a.doc_ctrl_num,     
		0,              b.apply_to_num,     b.trx_type,
		a.date_doc,     a.date_applied,    	0,
		0,              b.vendor_code,  	b.pay_to_code,
		b.class_code,   b.branch_code,  	-a.amt_payment,   
		0,              b.cash_acct_code,   0,
		0,				b.nat_cur_code, 	b.rate_home,
		b.rate_oper,	@journal_ctrl_num,	dbo.IBAcctMask_fn ( d.dm_on_acct_code, a.org_id),
		a.org_id,		2 								
FROM    #appapyt_work a, #appaxage_work b, #appatrxp_work c, apaccts d
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND		a.doc_ctrl_num = c.doc_ctrl_num
AND     c.posting_code = d.posting_code
AND		a.payment_type = 3
AND		b.apply_trx_type = 0
AND     a.db_action IN (0,1)    
AND     a.void_type = 4

IF(@@error != 0)
		RETURN -1






INSERT  #appaxage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		paid_flag,      cash_acct_code, 	amt_paid_to_date,
		date_paid,		nat_cur_code,		rate_home,		
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,			db_action )				
SELECT  a.trx_ctrl_num, 4181,		  	a.doc_ctrl_num,     
		0,              b.apply_to_num,     b.trx_type,
		a.date_doc,     a.date_applied,    	0,
		0,              b.vendor_code,  	b.pay_to_code,
		b.class_code,   b.branch_code,  	-a.amt_payment,   
		0,              dbo.IBAcctMask_fn ( b.cash_acct_code, b.org_id),   0,
		0,				b.nat_cur_code, 	b.rate_home,
		b.rate_oper,	@journal_ctrl_num,	dbo.IBAcctMask_fn ( c.on_acct_code, a.org_id),
		a.org_id,		2 								 
FROM    #appapyt_work a, #appaxage_work b, appymeth c
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND		a.payment_code = c.payment_code
AND		a.payment_type != 3
AND		b.apply_trx_type = 0
AND     a.db_action IN (0,1)    
AND     a.void_type = 4

IF(@@error != 0)
		RETURN -1







INSERT  #appaxage_work (
		trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		paid_flag,      cash_acct_code, 	amt_paid_to_date,
		date_paid,		nat_cur_code,		rate_home,		
		rate_oper,		journal_ctrl_num,	account_code,
		org_id,			db_action )				
SELECT  b.trx_ctrl_num, 4171,  			b.doc_ctrl_num,     
		0,              b.trx_ctrl_num,     b.trx_type,   		
		b.date_doc,     b.date_applied,    	0,
		0,              b.vendor_code,  	b.pay_to_code,
		b.class_code,   b.branch_code,  	-b.amount,   		   
		0,              dbo.IBAcctMask_fn ( b.cash_acct_code, b.org_id),   0,
		0,				b.nat_cur_code, 	b.rate_home,
		b.rate_oper,	@journal_ctrl_num,	dbo.IBAcctMask_fn ( b.account_code, b.org_id),
		a.org_id,		2 								  
FROM    #appapyt_work a, #appaxage_work b
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND		b.apply_trx_type = 0
AND     a.db_action = 0
AND     a.void_type = 4
AND     ((-b.amount) > (0.0) + 0.0000001)       


IF(@@error != 0)
		RETURN -1




UPDATE  #appappdt_work
SET     void_flag = 1,
		db_action = #appappdt_work.db_action | 1
FROM    #appappdt_work, #appatrxp_work b, #appapyt_work c, #appapdt_work d
WHERE   #appappdt_work.trx_ctrl_num = b.trx_ctrl_num
AND   c.trx_ctrl_num = d.trx_ctrl_num
AND   b.doc_ctrl_num = c.doc_ctrl_num
AND   b.cash_acct_code = c.cash_acct_code
AND   #appappdt_work.sequence_id = d.sequence_id

IF(@@error != 0)
		RETURN -1





UPDATE #appadsb_work   
SET db_action = #appadsb_work.db_action | 4
FROM    #appadsb_work, #appatrxp_work b, #appapyt_work c, #appapdt_work d
WHERE   #appadsb_work.trx_ctrl_num = b.trx_ctrl_num
AND   c.trx_ctrl_num = d.trx_ctrl_num
AND   b.doc_ctrl_num = c.doc_ctrl_num
AND   b.cash_acct_code = c.cash_acct_code
AND   #appadsb_work.sequence_id = d.sequence_id

IF(@@error != 0)
		RETURN -1




UPDATE  #appatrxp_work
SET     void_flag = 1,
		db_action = #appatrxp_work.db_action | 1
FROM    #appatrxp_work, #appapyt_work b
WHERE   #appatrxp_work.doc_ctrl_num = b.doc_ctrl_num
AND     #appatrxp_work.cash_acct_code = b.cash_acct_code
AND     #appatrxp_work.trx_type IN (4111,4011)
AND     b.void_type != 4

IF(@@error != 0)
		RETURN -1

UPDATE #appatrxv_work
SET amt_paid_to_date = amt_paid_to_date - (SELECT sum(b.vo_amt_applied + b.vo_amt_disc_taken)
						 FROM #appapdt_work b
						 WHERE b.apply_to_num = #appatrxv_work.trx_ctrl_num),
	paid_flag = 0,
	date_paid = 0,
	db_action = db_action | 1
FROM #appatrxv_work 

IF(@@error != 0)
		RETURN -1

UPDATE #appaxage_work
SET paid_flag = 0,
	db_action = db_action | 1
FROM #appaxage_work 
WHERE trx_type = 4091

IF(@@error != 0)
		RETURN -1

UPDATE #appatrxp_work
SET  amt_on_acct = #appatrxp_work.amt_on_acct + b.amt_payment,
	 amt_discount = #appatrxp_work.amt_discount - b.amt_disc_taken,
	 db_action = #appatrxp_work.db_action | 1
FROM #appatrxp_work, #appapyt_work b
WHERE #appatrxp_work.doc_ctrl_num = b.doc_ctrl_num
AND #appatrxp_work.cash_acct_code = b.cash_acct_code
AND #appatrxp_work.trx_type IN (4111,4011)
AND b.void_type = 4

IF(@@error != 0)
		RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appaupr.cpp' + ', line ' + STR( 352, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAUpdatePostedRecords_sp] TO [public]
GO
