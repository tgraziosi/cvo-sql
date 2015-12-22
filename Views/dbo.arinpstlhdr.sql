SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[arinpstlhdr]
			AS
			  SELECT timestamp, settlement_ctrl_num, description, hold_flag, posted_flag, date_entered, date_applied, user_id, 
				process_group_num, doc_count_expected, doc_count_entered, doc_sum_expected, doc_sum_entered, cr_total_home, 
				cr_total_oper, oa_cr_total_home, oa_cr_total_oper, cm_total_home, cm_total_oper, inv_total_home, inv_total_oper, 
				disc_total_home, disc_total_oper, wroff_total_home, wroff_total_oper, onacct_total_home, onacct_total_oper, 
				gain_total_home, gain_total_oper, loss_total_home, loss_total_oper, customer_code, nat_cur_code, batch_code, 
				rate_type_home, rate_home, rate_type_oper, rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, 
				settle_flag, org_id 
			  FROM arinpstlhdr_all 
GO
GRANT REFERENCES ON  [dbo].[arinpstlhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpstlhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpstlhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpstlhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpstlhdr] TO [public]
GO
