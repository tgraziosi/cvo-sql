SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[apinppyt]
			AS
			SELECT timestamp, trx_ctrl_num, trx_type, doc_ctrl_num, trx_desc, batch_code, cash_acct_code, 
				date_entered, date_applied, date_doc, vendor_code, pay_to_code, approval_code, payment_code, 
				payment_type, amt_payment, amt_on_acct, posted_flag, printed_flag, hold_flag, approval_flag, 
				gen_id, user_id, void_type, amt_disc_taken, print_batch_num, company_code, process_group_num,
				nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, payee_name, settlement_ctrl_num, 
				doc_amount, org_id 
			FROM apinppyt_all 
GO
GRANT REFERENCES ON  [dbo].[apinppyt] TO [public]
GO
GRANT SELECT ON  [dbo].[apinppyt] TO [public]
GO
GRANT INSERT ON  [dbo].[apinppyt] TO [public]
GO
GRANT DELETE ON  [dbo].[apinppyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinppyt] TO [public]
GO
