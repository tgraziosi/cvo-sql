SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[arinppyt]
			AS
			  SELECT timestamp, trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, non_ar_flag, non_ar_doc_num, 
				gl_acct_code, date_entered, date_applied, date_doc, customer_code, payment_code, payment_type, amt_payment, 
				amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp, deposit_num, bal_fwd_flag, printed_flag,
				 posted_flag, hold_flag, wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type, cash_acct_code, 
				origin_module_flag, process_group_num, source_trx_ctrl_num, source_trx_type, nat_cur_code, rate_type_home, 
				rate_type_oper, rate_home, rate_oper, amt_discount, reference_code, settlement_ctrl_num, doc_amount, org_id 
			  FROM arinppyt_all 
GO
GRANT REFERENCES ON  [dbo].[arinppyt] TO [public]
GO
GRANT SELECT ON  [dbo].[arinppyt] TO [public]
GO
GRANT INSERT ON  [dbo].[arinppyt] TO [public]
GO
GRANT DELETE ON  [dbo].[arinppyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinppyt] TO [public]
GO
