SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE  VIEW [dbo].[appyhdr] AS  
				SELECT timestamp, trx_ctrl_num, doc_ctrl_num, batch_code, date_posted, date_applied, date_doc, 
					date_entered, vendor_code, pay_to_code, approval_code, cash_acct_code, payment_code, state_flag, void_flag, 
					amt_net, amt_discount, amt_on_acct, payment_type, doc_desc, user_id, journal_ctrl_num, print_batch_num, 
					process_ctrl_num, currency_code, rate_type_home, rate_type_oper, rate_home, rate_oper, payee_name, 
					settlement_ctrl_num, org_id 
				FROM appyhdr_all 
GO
GRANT REFERENCES ON  [dbo].[appyhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[appyhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[appyhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[appyhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[appyhdr] TO [public]
GO
