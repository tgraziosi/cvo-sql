SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE PROC [dbo].[CMBTValidate_sp]	@debug_level		smallint = 0
	
AS


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtv.cpp" + ", line " + STR( 43, 5 ) + " -- ENTRY: "
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtv.cpp" + ", line " + STR( 44, 5 ) + " -- MSG: " + "Load #cmbtvhdr"
INSERT #cmbtvhdr 
(
	trx_ctrl_num,
	trx_type,
	description,
	doc_ctrl_num,
	date_applied,
	date_document,
	date_entered,
	cash_acct_code_from,
	cash_acct_code_to,
	acct_code_trans_from,
	acct_code_trans_to,
	acct_code_clr,
	currency_code_from,
	currency_code_to,
	curr_code_trans_from,
	curr_code_trans_to,
	trx_type_cls_from,
	trx_type_cls_to,
 	amount_from,
 	amount_to,
 	bank_charge_amt_from,
 	bank_charge_amt_to,
	batch_code,
	user_id,
	hold_flag,
	posted_flag,
	auto_rec_flag,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	from_reference_code,
	from_expense_account_code,
	from_expense_reference_code,	 
	to_reference_code,
	to_expense_account_code,
	to_expense_reference_code,	 
	flag,
	from_org_id,
	to_org_id
)
SELECT 
	a.trx_ctrl_num,
	a.trx_type,
	a.description,
	a.doc_ctrl_num,
	a.date_applied,
	a.date_document,
	a.date_entered,
	a.cash_acct_code_from,
	a.cash_acct_code_to,
	a.acct_code_trans_from,
	a.acct_code_trans_to,
	a.acct_code_clr,
	a.currency_code_from,
	a.currency_code_to,
	a.curr_code_trans_from,
	a.curr_code_trans_to,
	a.trx_type_cls_from,
	a.trx_type_cls_to,
 	a.amount_from,
 	a.amount_to,
 	a.bank_charge_amt_from,
 	a.bank_charge_amt_to,
	a.batch_code,
	a.user_id,
	a.auto_rec_flag,
	a.hold_flag,
	a.posted_flag,
	a.rate_type_home,
	a.rate_type_oper,
	a.rate_home_from,
	a.rate_oper_from,
	a.from_reference_code,
	a.from_expense_account_code,
	a.from_expense_reference_code,	 
	a.to_reference_code,
	a.to_expense_account_code,
	a.to_expense_reference_code,
	0,
	a.from_org_id,
	a.to_org_id
FROM	#cminpbtr_work a, apcash b
WHERE a.cash_acct_code_from = b.cash_acct_code


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtv.cpp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMBTValidate_sp] TO [public]
GO
