SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APPAInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
                    @date_applied int,
                    @debug_level smallint = 0
AS

DECLARE @current_date int      
               
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appaipr.cpp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "


EXEC appdate_sp @current_date OUTPUT    





INSERT  #appaxage_work (
      trx_ctrl_num,   trx_type,         doc_ctrl_num,
      ref_id,         apply_to_num,     apply_trx_type,
      date_doc,       date_applied,     date_due,
      date_aging,     vendor_code,      pay_to_code,
      class_code,     branch_code,      amount,
      paid_flag,      cash_acct_code,   amt_paid_to_date,
      date_paid,    nat_cur_code,   rate_home,
      rate_oper,    journal_ctrl_num, account_code,
	org_id,      db_action )
 SELECT   b.trx_ctrl_num,   4113,               a.doc_ctrl_num,
      0,              a.trx_ctrl_num,     a.apply_trx_type,
      a.date_doc,       b.date_applied,     0,
      0,            a.vendor_code,    a.pay_to_code,
      a.class_code,     a.branch_code,      -a.amount,
      0,                a.cash_acct_code,   0,
      0,          a.nat_cur_code,   a.rate_home,
      a.rate_oper,    @journal_ctrl_num,  c.on_acct_code,
      b.org_id,	2
 FROM       #appaxage_work a, #appapyt_work b, appymeth c
 WHERE      a.apply_trx_type = 0
 AND        a.doc_ctrl_num = b.doc_ctrl_num
 AND        a.cash_acct_code = b.cash_acct_code
 AND    b.payment_code = c.payment_code
 AND    a.trx_type = 4111
 AND    b.void_type IN (1,2,3,5)

 IF(@@error != 0)
      RETURN -1


INSERT  #appaxage_work (
      trx_ctrl_num,   trx_type,         doc_ctrl_num,
      ref_id,         apply_to_num,     apply_trx_type,
      date_doc,       date_applied,     date_due,
      date_aging,     vendor_code,      pay_to_code,
      class_code,     branch_code,      amount,
      paid_flag,      cash_acct_code,   amt_paid_to_date,
      date_paid,    nat_cur_code,   rate_home,
      rate_oper,    journal_ctrl_num, account_code,
      org_id,	db_action )

 SELECT   DISTINCT b.trx_ctrl_num,   4181,        a.doc_ctrl_num,
      0,              a.apply_to_num,     a.apply_trx_type,
      a.date_doc,       b.date_applied,     0,
      0,            a.vendor_code,      a.pay_to_code,
      a.class_code,     a.branch_code,     -a.amount,
      0,                a.cash_acct_code,   0,
      0,          a.nat_cur_code,   a.rate_home,
      a.rate_oper,    @journal_ctrl_num,  a.account_code,
	b.org_id,	2
 FROM       #appaxage_work a, #appapyt_work b, #appatrxp_work c
 WHERE      a.doc_ctrl_num = b.doc_ctrl_num
 AND        a.cash_acct_code = b.cash_acct_code




 
 AND    b.void_type IN (1,2,5)
 AND    a.trx_type = 4171

 IF(@@error != 0)
      RETURN -1






INSERT #appaxage_work (
 trx_ctrl_num, trx_type, doc_ctrl_num,
 ref_id, apply_to_num, apply_trx_type,
 date_doc, date_applied, date_due,
 date_aging, vendor_code, pay_to_code,
 class_code, branch_code, amount,
 paid_flag, cash_acct_code, amt_paid_to_date,
 date_paid, nat_cur_code, rate_home,
 rate_oper, journal_ctrl_num, account_code,
      org_id,	 db_action )

 SELECT DISTINCT b.trx_ctrl_num, 4181, a.doc_ctrl_num,    
 0, a.apply_to_num, a.apply_trx_type,
 a.date_doc, b.date_applied, 0,
 0, a.vendor_code, a.pay_to_code,
 a.class_code, a.branch_code,  -a.amount,
 0, a.cash_acct_code, 0,
 0, a.nat_cur_code, a.rate_home,
 a.rate_oper, @journal_ctrl_num, a.account_code,
     b.org_id,	 2
 FROM #appaxage_work a, #appapyt_work b, #appatrxp_work c
 WHERE a.doc_ctrl_num = b.doc_ctrl_num
 AND a.cash_acct_code = b.cash_acct_code
 AND b.void_type IN (3)
 AND a.trx_type = 4171   
 AND b.doc_ctrl_num not in (	SELECT b.doc_ctrl_num    
	FROM #appaxage_work a, #appapyt_work b, #appatrxp_work c
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND b.void_type IN (3)
	AND a.trx_type = 4181)   
 AND b.doc_ctrl_num not in (	SELECT  b.doc_ctrl_num   
 	FROM aptrxage a, #appapyt_work b, #appatrxp_work c 
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND b.void_type IN (3)
	AND a.trx_type = 4181)   
 
 IF(@@error != 0)
 RETURN -1






INSERT  #appatrx_work  (
     trx_ctrl_num,          doc_ctrl_num,   batch_code,
     date_applied,          date_doc,     date_entered,
     vendor_code,           pay_to_code,    branch_code,
     class_code,      approval_code,    cash_acct_code,
     payment_code,      void_flag,      amt_gross,
     amt_discount,      amt_net,      amt_on_acct,
     payment_type,      doc_desc,     user_id,
     gl_trx_id,       print_batch_num,  company_code,
     nat_cur_code,      rate_type_home,   rate_type_oper,
     rate_home,       rate_oper,            org_id,	db_action  )                        
SELECT  
     a.trx_ctrl_num,  a.doc_ctrl_num,   a.batch_code,
     a.date_applied,  a.date_doc,     a.date_entered,
     a.vendor_code,   a.pay_to_code,    b.branch_code,
     b.class_code,    a.approval_code,  a.cash_acct_code,
     a.payment_code,  a.void_type,    a.amt_payment,
     a.amt_disc_taken,  a.amt_payment,    a.amt_on_acct,
     a.payment_type,  a.trx_desc,     a.user_id,
     @journal_ctrl_num, a.print_batch_num,  a.company_code,
     a.nat_cur_code,  a.rate_type_home, a.rate_type_oper,
     a.rate_home,   a.rate_oper,          a.org_id,	2
FROM    #appapyt_work a, #appatrxp_work b
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND a.cash_acct_code = b.cash_acct_code






INSERT  #appaxpdt_work (
      doc_ctrl_num, trx_ctrl_num,   trx_type,
      sequence_id,  apply_to_num,   apply_trx_type,
      vendor_code,  date_apply_doc,   date_aging,
      amt_applied,  amt_disc_taken,   line_desc,      
      void_flag,    posted_flag,    payment_hold_flag,
      vo_amt_applied, vo_amt_disc_taken,  gain_home,
      gain_oper,          org_id,	db_action )
SELECT  b.doc_ctrl_num,   b.trx_ctrl_num,     b.trx_type,
    c.sequence_id,    c.apply_to_num,     4091,
    b.vendor_code,    d.date_apply_doc,   d.date_aging,
    c.amt_applied,    c.amt_disc_taken,   c.line_desc,   
    0,          0,            0,
    c.vo_amt_applied, c.vo_amt_disc_taken,  c.gain_home,
    c.gain_oper,         b.org_id,	2
FROM    #appapyt_work b, #appapdt_work c, #appappdt_work d, #appatrxp_work e
WHERE   b.doc_ctrl_num = e.doc_ctrl_num
AND   b.cash_acct_code = e.cash_acct_code
AND   d.trx_ctrl_num = e.trx_ctrl_num
AND   b.trx_ctrl_num = c.trx_ctrl_num
AND   c.sequence_id = d.sequence_id

IF(@@error != 0)
  RETURN -1





IF EXISTS ( SELECT DISTINCT 1    
	FROM #appaxage_work a, #appapyt_work b, #appatrxp_work c
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND b.void_type IN (3)
	AND a.trx_type = 4113) 
BEGIN


INSERT  #appaxage_work (
  trx_ctrl_num,   trx_type,         doc_ctrl_num,
  ref_id,         apply_to_num,     apply_trx_type,
  date_doc,       date_applied,     date_due,
  date_aging,     vendor_code,      pay_to_code,
  class_code,     branch_code,      amount,
  amt_paid_to_date, paid_flag,      cash_acct_code,
  date_paid,    nat_cur_code,   rate_home,
  rate_oper,    journal_ctrl_num, account_code,
      org_id,	  db_action )
SELECT  b.trx_ctrl_num,     
    (1 - SIGN(ABS(1-b.void_type))) * 4121 +
    (1 - SIGN(ABS(2-b.void_type))) * 4115 + 
    (1 - SIGN(ABS(3-b.void_type))) * 4112 +
    (1 - SIGN(ABS(4-b.void_type))) * 4112 +
    (1 - SIGN(ABS(5-b.void_type))) * 4114 ,     
  b.doc_ctrl_num,
  a.ref_id,     a.apply_to_num,   4091,
  a.date_doc,     b.date_applied,   a.date_due,
  a.date_aging,   a.vendor_code,    a.pay_to_code,
  a.class_code,   a.branch_code,    -a.amount,
  0,              0,         a.cash_acct_code,
  0,        a.nat_cur_code,   a.rate_home,
  a.rate_oper,  @journal_ctrl_num,  dbo.IBAcctMask_fn(e.ap_acct_code,c.org_id),				
      d.org_id,	  2 							
FROM    #appaxage_work a, #appapyt_work b, #appapdt_work c, #appatrxv_work d, apaccts e
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND     b.trx_ctrl_num = c.trx_ctrl_num
AND   c.apply_to_num = d.trx_ctrl_num
AND   d.posting_code = e.posting_code
AND     a.ref_id = c.sequence_id
AND     a.trx_type IN (4111,4011,4161)

END
ELSE
BEGIN

INSERT  #appaxage_work (
  trx_ctrl_num,   trx_type,         doc_ctrl_num,
  ref_id,         apply_to_num,     apply_trx_type,
  date_doc,       date_applied,     date_due,
  date_aging,     vendor_code,      pay_to_code,
  class_code,     branch_code,      amount,
  amt_paid_to_date, paid_flag,      cash_acct_code,
  date_paid,    nat_cur_code,   rate_home,
  rate_oper,    journal_ctrl_num, account_code,
      org_id,	  db_action )
SELECT  b.trx_ctrl_num,     
    (1 - SIGN(ABS(1-b.void_type))) * 4121 +
    (1 - SIGN(ABS(2-b.void_type))) * 4115 + 
    (1 - SIGN(ABS(3-b.void_type))) * 4113 +
    (1 - SIGN(ABS(4-b.void_type))) * 4112 +
    (1 - SIGN(ABS(5-b.void_type))) * 4114 ,     
  b.doc_ctrl_num,
  a.ref_id,     a.apply_to_num,   4091,
  a.date_doc,     b.date_applied,   a.date_due,
  a.date_aging,   a.vendor_code,    a.pay_to_code,
  a.class_code,   a.branch_code,    -a.amount,
  0,              0,                a.cash_acct_code,
  0,        a.nat_cur_code,   a.rate_home,
  a.rate_oper,  @journal_ctrl_num,  dbo.IBAcctMask_fn(e.ap_acct_code,c.org_id),				
      d.org_id,	  2 							
FROM    #appaxage_work a, #appapyt_work b, #appapdt_work c, #appatrxv_work d, apaccts e
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND     b.trx_ctrl_num = c.trx_ctrl_num
AND   c.apply_to_num = d.trx_ctrl_num
AND   d.posting_code = e.posting_code
AND     a.ref_id = c.sequence_id
AND     a.trx_type IN (4111,4011,4161)

IF(@@error != 0)
  RETURN -1

END



INSERT  #appaxage_work (
  trx_ctrl_num,   trx_type,         doc_ctrl_num,
  ref_id,         apply_to_num,     apply_trx_type,
  date_doc,       date_applied,     date_due,
  date_aging,     vendor_code,      pay_to_code,
  class_code,     branch_code,      amount,
  amt_paid_to_date, paid_flag,      cash_acct_code,
  date_paid,    nat_cur_code,   rate_home,
  rate_oper,    journal_ctrl_num, account_code,
      org_id,	  db_action )
SELECT  b.trx_ctrl_num,  4132,      b.doc_ctrl_num,
  a.ref_id,     a.apply_to_num,   4091,
  a.date_doc,     b.date_applied,   a.date_due,
  a.date_aging,   a.vendor_code,    a.pay_to_code,
  a.class_code,   a.branch_code,    -a.amount,
  0,              0,                a.cash_acct_code,
  0,        a.nat_cur_code,   a.rate_home,
  a.rate_oper,  @journal_ctrl_num,  dbo.IBAcctMask_fn(e.ap_acct_code,b.org_id),
      d.org_id,	  2 						
FROM    #appaxage_work a, #appapyt_work b, #appapdt_work c, #appatrxv_work d, apaccts e
WHERE   a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND     b.trx_ctrl_num = c.trx_ctrl_num
AND   c.apply_to_num = d.trx_ctrl_num
AND   d.posting_code = e.posting_code
AND     a.ref_id = c.sequence_id
AND     a.trx_type = 4131


IF(@@error != 0)
  RETURN -1


IF EXISTS ( SELECT 1 FROM  aptrxage  nolock  WHERE trx_type = 4181 
        and  doc_ctrl_num = ( SELECT DISTINCT b.doc_ctrl_num 
	FROM #appaxage_work a, #appapyt_work b
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND b.void_type IN (3)
	AND a.trx_type = 4113 ) ) 
BEGIN


INSERT #appaxage_work (
 trx_ctrl_num,  trx_type,   doc_ctrl_num,
 ref_id,    apply_to_num, apply_trx_type,
 date_doc,   date_applied,  date_due,
 date_aging,  vendor_code,  pay_to_code,
 class_code,  branch_code, amount,
 paid_flag,  cash_acct_code,  amt_paid_to_date,
 date_paid, nat_cur_code,  rate_home,
 rate_oper,  journal_ctrl_num,  account_code,
 org_id,  db_action )
SELECT  b.trx_ctrl_num,    4181,    b.doc_ctrl_num,
  0,     z.trx_ctrl_num,   z.trx_type,
  a.date_doc,     b.date_applied,   0,
  0,   a.vendor_code,    a.pay_to_code,
  a.class_code,   a.branch_code,   a.amount,
  0, a.cash_acct_code, 0 ,
  0 ,  a.nat_cur_code,   a.rate_home,
  a.rate_oper,  @journal_ctrl_num,  dbo.IBAcctMask_fn(e.ap_acct_code,c.org_id),				
  d.org_id,	  2 							
FROM    #appaxage_work a, #appapyt_work b, #appapdt_work c, 
        #appatrxv_work d, apaccts e, #appatrxp_work z
WHERE  ( a.doc_ctrl_num = b.doc_ctrl_num
AND     a.cash_acct_code = b.cash_acct_code
AND     b.trx_ctrl_num = c.trx_ctrl_num
AND   c.apply_to_num = d.trx_ctrl_num
AND   d.posting_code = e.posting_code
AND     a.ref_id = c.sequence_id
AND     a.trx_type IN (4111))
AND     z.doc_ctrl_num = a.doc_ctrl_num
AND b.doc_ctrl_num  in ( SELECT DISTINCT b.doc_ctrl_num    
	FROM #appaxage_work a, #appapyt_work b, #appatrxp_work c
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code
	AND b.void_type IN (3)
	AND a.trx_type = 4113) 
/*  
IF(@@error != 0)
  RETURN -1
*/
	

END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appaipr.cpp" + ", line " + STR( 324, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAInsertPostedRecords_sp] TO [public]
GO
