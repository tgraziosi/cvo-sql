SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[apinpstl]
			AS
			SELECT timestamp, settlement_ctrl_num, vendor_code, pay_to_code, hold_flag, date_entered, date_applied, user_id, batch_code, 
			process_group_num, state_flag, disc_total_home, disc_total_oper, debit_memo_total_home, debit_memo_total_oper, on_acct_pay_total_home, 
			on_acct_pay_total_oper, payments_total_home,payments_total_oper, put_on_acct_total_home, put_on_acct_total_oper, gain_total_home, 
			gain_total_oper, loss_total_home, loss_total_oper, description,nat_cur_code, doc_count_expected, doc_count_entered, doc_sum_expected, 
			doc_sum_entered, vo_total_home, vo_total_oper, rate_type_home, rate_home,rate_type_oper, rate_oper, vo_amt_nat, amt_doc_nat, amt_dist_nat, 
			amt_on_acct, org_id
			FROM apinpstl_all 
GO
GRANT REFERENCES ON  [dbo].[apinpstl] TO [public]
GO
GRANT SELECT ON  [dbo].[apinpstl] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpstl] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpstl] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpstl] TO [public]
GO
