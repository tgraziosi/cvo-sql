SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE        [dbo].[appyval_sp] @debug_level smallint = 0
			
AS

DECLARE @result int                

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyval.cpp" + ", line " + STR( 32, 5 ) + " -- ENTRY: "

IF (SELECT COUNT(1) FROM #apinppyt) = 0
   RETURN -2


INSERT #appyvpyt (
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num,
	trx_desc,
	batch_code,
	cash_acct_code,
	date_entered,
	date_applied,
	date_doc,
    vendor_code,
	pay_to_code,
	approval_code,
	payment_code,
	payment_type,
    amt_payment,
	amt_on_acct,
	posted_flag,
	printed_flag,
	hold_flag,
	approval_flag,
	user_id,
	amt_disc_taken,
	print_batch_num,
 	company_code,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	flag,
	org_id,
	interbranch_flag,
	temp_flag ) 
SELECT 
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num,
	trx_desc,
	batch_code, 
	cash_acct_code,
	date_entered,
	date_applied,
	date_doc,
    vendor_code,
	pay_to_code,
	approval_code,
	payment_code,
	payment_type,
    amt_payment,
	amt_on_acct,
	0,
	printed_flag,
	hold_flag,
	0,
	user_id,
	amt_disc_taken,
	print_batch_num, 
 	company_code,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	0,
	org_id,
	0,
	0
FROM	#apinppyt



INSERT #appyvpdt (
	trx_ctrl_num,
	trx_type,
	sequence_id,
	apply_to_num,
	apply_trx_type,
	amt_applied,
	amt_disc_taken,
	line_desc,
	payment_hold_flag,
	vendor_code,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper,
	nat_cur_code,
	org_id) 
SELECT
	trx_ctrl_num,
	trx_type,
	sequence_id,
	apply_to_num,
	apply_trx_type,
	amt_applied,
	amt_disc_taken,
	line_desc,
	payment_hold_flag,
	vendor_code,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper,
	nat_cur_code,
	org_id
FROM #apinppdt



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyval.cpp" + ", line " + STR( 148, 5 ) + " -- EXIT: "
			




RETURN 0

GO
GRANT EXECUTE ON  [dbo].[appyval_sp] TO [public]
GO
