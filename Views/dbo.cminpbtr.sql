SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[cminpbtr]
			AS
			  SELECT timestamp, trx_ctrl_num, description, doc_ctrl_num, date_applied, date_document, date_entered, 
				cash_acct_code_from, cash_acct_code_to, currency_code_from, currency_code_to, amount_from, amount_to, 
				bank_charge_amt_from, bank_charge_amt_to, trx_type_cls_from, trx_type_cls_to, exchange_rate, hold_flag, 
				prc_gl_flag, posted_flag, user_id, batch_code, process_group_num, to_reference_code, to_expense_account_code, 
				to_expense_reference_code, from_reference_code, from_expense_account_code, from_expense_reference_code, 
				from_org_id, to_org_id 
			  FROM cminpbtr_all 
GO
GRANT REFERENCES ON  [dbo].[cminpbtr] TO [public]
GO
GRANT SELECT ON  [dbo].[cminpbtr] TO [public]
GO
GRANT INSERT ON  [dbo].[cminpbtr] TO [public]
GO
GRANT DELETE ON  [dbo].[cminpbtr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cminpbtr] TO [public]
GO
