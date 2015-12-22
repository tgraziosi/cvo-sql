SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[cmtrxbtr]
			AS
			  SELECT  timestamp, trx_ctrl_num, trx_type, description, doc_ctrl_num, date_applied, date_document, 
				date_entered, date_posted, cash_acct_code_from, cash_acct_code_to, acct_code_trans_from, 
				acct_code_trans_to, acct_code_clr, currency_code_from, currency_code_to, curr_code_trans_from, 
				curr_code_trans_to, trx_type_cls_from, trx_type_cls_to, amount_from, amount_to, bank_charge_amt_from, 
				bank_charge_amt_to, batch_code, gl_trx_id, user_id, auto_rec_flag, to_reference_code, to_expense_account_code, 
				to_expense_reference_code, from_reference_code, from_expense_account_code, from_expense_reference_code, 
				from_org_id, to_org_id 
			  FROM cmtrxbtr_all 
GO
GRANT REFERENCES ON  [dbo].[cmtrxbtr] TO [public]
GO
GRANT SELECT ON  [dbo].[cmtrxbtr] TO [public]
GO
GRANT INSERT ON  [dbo].[cmtrxbtr] TO [public]
GO
GRANT DELETE ON  [dbo].[cmtrxbtr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmtrxbtr] TO [public]
GO
