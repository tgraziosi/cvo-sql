SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPYModifyPersistant_sp]
											@batch_ctrl_num         varchar(16),
											@client_id              varchar(20),
											@user_id                smallint, 
											@process_group_num		varchar(16), 
											@debug_level            smallint = 0

AS

DECLARE
	@errbuf                         varchar(100),
	@result                         int,
	@current_date					int,
	@settlement_ctrl_num		varchar(16)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 123, 5 ) + " -- ENTRY: "


EXEC appdate_sp @current_date OUTPUT		







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 134, 5 ) + " -- MSG: " + "Update activity tables"



EXEC @result = APPYUPActivity_sp     @batch_ctrl_num, 
								@client_id,
								@user_id,
								@debug_level


IF(@result != 0 )
	RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 148, 5 ) + " -- MSG: " + "insert records in appydsb"

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
FROM #appydsb_work  
WHERE db_action = 2 

IF (@@error != 0)  
	RETURN -1

















IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 188, 5 ) + " -- MSG: " + "delete apexpdst"

DELETE  apexpdst
FROM    #appypyt_work t
	INNER JOIN apexpdst a ON t.vendor_code = a.vendor_code AND   t.doc_ctrl_num = a.check_num AND   t.cash_acct_code = a.cash_acct_code

IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 201, 5 ) + " -- MSG: " + "delete apinppdt"
DELETE  apinppdt
FROM    #appypdt_work t
	INNER JOIN apinppdt a ON t.trx_ctrl_num = a.trx_ctrl_num AND t.trx_type = a.trx_type AND t.sequence_id = a.sequence_id
WHERE  (t.db_action & 4) = 4
IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 213, 5 ) + " -- MSG: " + "delete records in apinppyt"

DELETE  apinppyt_all
FROM    #appypyt_work t
	INNER JOIN apinppyt_all a ON t.trx_ctrl_num = a.trx_ctrl_num AND  t.trx_type = a.trx_type
WHERE  (t.db_action & 4) = 4
IF (@@error != 0)
	RETURN -1






SELECT 	@settlement_ctrl_num = settlement_ctrl_num
FROM	#appypyt_work 
WHERE	(db_action & 4) = 4
IF (@@error != 0)
	RETURN -1

IF (@settlement_ctrl_num is not null)
BEGIN
	EXEC @result = apstlmp_sp @settlement_ctrl_num, @debug_level
	IF(@result != 0 )
		RETURN @result
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 240, 5 ) + " -- MSG: " + "Update summary tables"


EXEC @result = APPYUPSummary_sp     @batch_ctrl_num, 
								@client_id,
								@user_id,
								@debug_level

IF(@result != 0 )
	RETURN @result



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 253, 5 ) + " -- MSG: " + "update apvohdr vouchers"
UPDATE apvohdr
SET date_paid = b.date_paid,
    paid_flag = b.paid_flag,
	amt_paid_to_date = b.amt_paid_to_date,
	state_flag = 1,
	process_ctrl_num = ""
FROM apvohdr
	INNER JOIN #appytrxv_work b ON apvohdr.trx_ctrl_num = b.trx_ctrl_num

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 267, 5 ) + " -- MSG: " + "update appyhdr on-account payments"
UPDATE appyhdr
SET amt_on_acct = b.amt_on_acct,
	state_flag = 1,
	process_ctrl_num = ""
FROM appyhdr
	INNER JOIN #appytrxp_work b ON appyhdr.trx_ctrl_num = b.trx_ctrl_num

IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 282, 5 ) + " -- MSG: " + "Update apchkstb"

UPDATE 	apchkstb 
SET 	posted_flag = 1
FROM #appypyt_work t
	INNER JOIN apchkstb a ON t.doc_ctrl_num = a.check_num AND  t.cash_acct_code = a.cash_acct_code

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 293, 5 ) + " -- MSG: " + "insert in appyhdr"
INSERT  appyhdr(
	trx_ctrl_num,		doc_ctrl_num,		batch_code,
	date_posted,		date_applied,		date_doc,
	date_entered,		vendor_code,		pay_to_code,
	approval_code,		cash_acct_code,		payment_code,
	state_flag,			void_flag,			amt_net,
	amt_discount,		amt_on_acct,		payment_type,
	doc_desc,			user_id,			journal_ctrl_num,
	print_batch_num,	process_ctrl_num,	currency_code,
	rate_type_home,		rate_type_oper,		rate_home,
	rate_oper,			payee_name, settlement_ctrl_num, org_id
	)
	SELECT
		trx_ctrl_num,           doc_ctrl_num,           batch_code,
		@current_date,			date_applied,			date_doc,
		date_entered,			vendor_code,            pay_to_code,
		approval_code,          cash_acct_code,         payment_code,
		1,				0,						amt_net,
		amt_discount,			amt_on_acct,			payment_type,
		doc_desc,               user_id,                gl_trx_id,
		print_batch_num,        "",						nat_cur_code,			
		rate_type_home,			rate_type_oper,			rate_home,				
		rate_oper,payee_name,settlement_ctrl_num, org_id
FROM    #appytrx_work
WHERE   (db_action & 2) = 2

IF (@@error != 0)
	RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 325, 5 ) + " -- MSG: " + "update on account aptrxage records"
UPDATE aptrxage
SET paid_flag = b.paid_flag,
	date_paid = b.date_paid
FROM aptrxage
	INNER JOIN #appyageo_work b ON aptrxage.doc_ctrl_num = b.doc_ctrl_num AND aptrxage.cash_acct_code = b.cash_acct_code
WHERE aptrxage.apply_trx_type = 0


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 334, 5 ) + " -- MSG: " + "update aptrxage voucher records"
UPDATE  aptrxage
SET     paid_flag = b.paid_flag,
		date_paid = b.date_paid
FROM    aptrxage
	INNER JOIN #appyagev_work b ON aptrxage.trx_ctrl_num = b.trx_ctrl_num AND aptrxage.date_aging = b.date_aging
WHERE  aptrxage.trx_type = 4091


IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 347, 5 ) + " -- MSG: " + "insert aptrxage records"
INSERT  aptrxage (
	trx_ctrl_num,   trx_type,       	doc_ctrl_num,
	ref_id,         apply_to_num,   	apply_trx_type,
	date_doc,       date_applied,   	date_due,
	date_aging,     vendor_code,    	pay_to_code,
	class_code,     branch_code,    	amount,
	paid_flag,      cash_acct_code, 	amt_paid_to_date,
	date_paid,		nat_cur_code,		rate_home,
	rate_oper,		journal_ctrl_num,	account_code, org_id)

SELECT  trx_ctrl_num,   trx_type,       	doc_ctrl_num,
		ref_id,         apply_to_num,   	apply_trx_type,
		date_doc,       date_applied,   	date_due,
		date_aging,     vendor_code,    	pay_to_code,
		class_code,     branch_code,    	amount,
		0,      		cash_acct_code, 	0.0,
    	0,				nat_cur_code,		rate_home,
		rate_oper,		journal_ctrl_num,	account_code, org_id
FROM    #appyage_work
WHERE   (db_action & 2) = 2

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 373, 5 ) + " -- MSG: " + "insert aptrxpdt"



INSERT  appydet (
	trx_ctrl_num,
	sequence_id,
	apply_to_num,
	date_aging,
	date_applied,
	amt_applied,
	amt_disc_taken,
	line_desc,
	void_flag,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper, 
	org_id

 )
SELECT     
	trx_ctrl_num,
	sequence_id,
	apply_to_num,
	date_aging,
	date_apply_doc,
	amt_applied,
	amt_disc_taken,
	line_desc,
	0,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper,
	org_id
FROM    #appyxpdt_work
WHERE   (db_action & 2) = 2

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appymp.cpp" + ", line " + STR( 416, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYModifyPersistant_sp] TO [public]
GO
