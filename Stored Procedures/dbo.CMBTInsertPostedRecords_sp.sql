SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

						


CREATE PROC [dbo].[CMBTInsertPostedRecords_sp]  @journal_ctrl_num  varchar(16),
										@date_applied int,
										@debug_level smallint = 0
AS
			 
	DECLARE	@current_date int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtipr.cpp" + ", line " + STR( 47, 5 ) + " -- ENTRY: "
			 							 

EXEC appdate_sp @current_date OUTPUT		

INSERT #cmtrxbtr_work
(	
	trx_ctrl_num,
	trx_type,
	description,
	doc_ctrl_num,
	date_applied,
	date_document,
	date_entered,
	date_posted,
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
	gl_trx_id,
	user_id,
	auto_rec_flag,
	from_reference_code,
	from_expense_account_code,
	from_expense_reference_code,	 
	to_reference_code,
	to_expense_account_code,
	to_expense_reference_code,
	from_org_id,
	to_org_id
)
SELECT
	trx_ctrl_num,
	trx_type,
	description,
	doc_ctrl_num,
	date_applied,
	date_document,
	date_entered,
	@current_date,
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
	@journal_ctrl_num,
	user_id,
	auto_rec_flag,
	from_reference_code,
	from_expense_account_code,
	from_expense_reference_code,	 
	to_reference_code,
	to_expense_account_code,
	to_expense_reference_code,
	from_org_id,
	to_org_id
FROM #cminpbtr_work


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtipr.cpp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMBTInsertPostedRecords_sp] TO [public]
GO
