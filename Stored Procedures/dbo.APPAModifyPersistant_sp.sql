SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APPAModifyPersistant_sp]
											@batch_ctrl_num         varchar(16),
											@client_id              varchar(20),
											@user_id                smallint,  
											@debug_level            smallint = 0

AS

DECLARE
	@errbuf         varchar(100),
	@result         int,
	@current_date	int

BEGIN
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appamp.cpp' + ', line ' + STR( 63, 5 ) + ' -- ENTRY: '

EXEC appdate_sp @current_date OUTPUT		







EXEC @result = APPAUPActivity_sp     @batch_ctrl_num, 
								@client_id,
								@user_id,
								@debug_level
IF(@result != 0 )
	RETURN @result

INSERT apchkdsb  (  check_ctrl_num,  
					onacct_ctrl_num,  
					trx_ctrl_num, 
					doc_ctrl_num,  
					sequence_id,  
					apply_to_num,  
					check_num,  
					cash_acct_code) 
SELECT  			check_ctrl_num, 
					onacct_ctrl_num,  
					trx_ctrl_num,  
					doc_ctrl_num,  
					sequence_id,  
					apply_to_num,  
					check_num, 
					cash_acct_code  
FROM #appadsb_work  
WHERE db_action = 2 

IF (@@error != 0)  
	RETURN -1

DELETE  apchkdsb
FROM    #appadsb_work t, apchkdsb a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
  AND   t.apply_to_num = a.apply_to_num
  AND   t.sequence_id  = a.sequence_id
  AND   (db_action & 4 ) = 4

IF (@@error != 0)  
	RETURN -1






UPDATE apchkdsb
   SET check_num = t.check_num,
	   cash_acct_code = t.cash_acct_code
  FROM apchkdsb, #appadsb_work t
 WHERE apchkdsb.onacct_ctrl_num = t.onacct_ctrl_num
   AND apchkdsb.apply_to_num = t.apply_to_num
   AND apchkdsb.trx_ctrl_num = t.trx_ctrl_num
   AND (db_action & 1) = 1

IF (@@error != 0)
	RETURN -1






DELETE  apinppdt
FROM    #appapdt_work t, apinppdt a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
AND     t.trx_type = a.trx_type
AND     t.sequence_id = a.sequence_id
AND             (t.db_action & 4) = 4
IF (@@error != 0)
	RETURN -1






DELETE  apinppyt
FROM    #appapyt_work t, apinppyt a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
AND     t.trx_type = a.trx_type
AND     (t.db_action & 4) = 4
IF (@@error != 0)
	RETURN -1





EXEC @result = APPAUPSummary_sp @batch_ctrl_num, 
								@client_id,
								@user_id,
								@debug_level
IF(@result != 0 )
	RETURN @result




UPDATE appyhdr
SET amt_on_acct = b.amt_on_acct,	   
	amt_discount = b.amt_discount,
	void_flag	= b.void_flag,
	state_flag = 1,
	process_ctrl_num = ''
FROM appyhdr, #appatrxp_work b
WHERE appyhdr.trx_ctrl_num = b.trx_ctrl_num


UPDATE apvohdr
SET date_paid = b.date_paid,	   
	paid_flag = b.paid_flag,
	amt_paid_to_date = b.amt_paid_to_date,
	state_flag = 1,
	process_ctrl_num = ''
FROM apvohdr, #appatrxv_work b
WHERE apvohdr.trx_ctrl_num = b.trx_ctrl_num


INSERT  appahdr(
	trx_ctrl_num,		doc_ctrl_num,	batch_code,
	date_posted,		date_applied,	date_entered,		
	cash_acct_code,		state_flag,		void_flag,
	doc_desc,			user_id,		journal_ctrl_num,	
	process_ctrl_num,      org_id
	)
SELECT  trx_ctrl_num,	doc_ctrl_num,	batch_code,
		@current_date,	date_applied,	date_entered,
		cash_acct_code,	1,		void_flag,
		doc_desc,		user_id,		gl_trx_id,
		'',      org_id
FROM    #appatrx_work
WHERE   (db_action & 2) = 2
IF (@@error != 0)
	RETURN -1





DELETE  aptrxage
FROM    #appaxage_work t, aptrxage a
WHERE   t.trx_ctrl_num = a.trx_ctrl_num
AND     t.trx_type = a.trx_type
AND     t.ref_id = a.ref_id
AND        (((t.db_action & 4) = 4)
OR          ((t.db_action & 1) = 1))
IF (@@error != 0)
	RETURN -1


INSERT  aptrxage (
	trx_ctrl_num,   trx_type,       	doc_ctrl_num,
	ref_id,         apply_to_num,   	apply_trx_type,
	date_doc,       date_applied,   	date_due,
	date_aging,     vendor_code,    	pay_to_code,
	class_code,     branch_code,    	amount,
	paid_flag,      cash_acct_code, 	amt_paid_to_date,
	date_paid,		nat_cur_code,		rate_home,
	rate_oper,		journal_ctrl_num,	account_code,      
	org_id)

SELECT  trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		paid_flag,      cash_acct_code, 	amt_paid_to_date,
		date_paid,		nat_cur_code,		rate_home,
		rate_oper,		journal_ctrl_num,	account_code,      
		org_id
FROM    #appaxage_work
WHERE   (db_action & 2) = 2
   OR   (db_action & 1) = 1

IF (@@error != 0)
	RETURN -1





UPDATE  appydet
SET void_flag = a.void_flag
FROM    #appappdt_work a, appydet
WHERE   a.trx_ctrl_num = appydet.trx_ctrl_num
AND     a.sequence_id = appydet.sequence_id
AND     a.db_action & 1 = 1
IF (@@error != 0)
	RETURN -1


INSERT  appadet (
	trx_ctrl_num,
	sequence_id,
	void_flag,      
	org_id
	 )
SELECT     
	trx_ctrl_num,
	sequence_id,
	void_flag,
	org_id
FROM    #appaxpdt_work
WHERE   db_action & 2 = 2

IF (@@error != 0)
	RETURN -1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appamp.cpp' + ', line ' + STR( 280, 5 ) + ' -- EXIT: '

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APPAModifyPersistant_sp] TO [public]
GO
