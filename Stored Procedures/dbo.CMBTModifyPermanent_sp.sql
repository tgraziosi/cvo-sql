SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

						



CREATE PROC [dbo].[CMBTModifyPermanent_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			int,  
											@debug_level		smallint = 0
	
AS

DECLARE
	@date_applied       int,
	@company_code       varchar(8),
	@current_date       int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtmp.cpp" + ", line " + STR( 53, 5 ) + " -- ENTRY: "




EXEC appdate_sp @current_date OUTPUT		

SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num

SELECT @company_code = company_code FROM glco





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtmp.cpp" + ", line " + STR( 70, 5 ) + " -- MSG: " + "update records in cminpbtr"
DELETE  cminpbtr
FROM	#cminpbtr_work a, cminpbtr b
WHERE   a.trx_ctrl_num = b.trx_ctrl_num

IF (@@error != 0)
	RETURN -1





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtmp.cpp" + ", line " + STR( 82, 5 ) + " -- MSG: " + "insert cmtrxbtr"
INSERT  cmtrxbtr
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

FROM    #cmtrxbtr_work

IF (@@error != 0)
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtmp.cpp" + ", line " + STR( 165, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMBTModifyPermanent_sp] TO [public]
GO
