SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[appystl]
			AS
			 SELECT timestamp, settlement_ctrl_num, vendor_code , pay_to_code, date_entered, date_applied, user_id, batch_code, process_group_num, 
			state_flag, disc_total_home, disc_total_oper, debit_memo_total_home, debit_memo_total_oper, on_acct_pay_total_home, on_acct_pay_total_oper, 
			payments_total_home, payments_total_oper, put_on_acct_total_home, put_on_acct_total_oper, gain_total_home, gain_total_oper, loss_total_home, 
			loss_total_oper, org_id
			  FROM appystl_all 
GO
GRANT REFERENCES ON  [dbo].[appystl] TO [public]
GO
GRANT SELECT ON  [dbo].[appystl] TO [public]
GO
GRANT INSERT ON  [dbo].[appystl] TO [public]
GO
GRANT DELETE ON  [dbo].[appystl] TO [public]
GO
GRANT UPDATE ON  [dbo].[appystl] TO [public]
GO
