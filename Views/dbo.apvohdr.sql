SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE  VIEW [dbo].[apvohdr] AS  
				SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num,
					 vend_order_num, ticket_num, date_posted, date_applied, date_aging, date_due, date_doc, date_entered,
					 date_received, date_required, date_paid, date_discount, posting_code, vendor_code, pay_to_code,
					 branch_code, class_code, approval_code, comment_code, fob_code, terms_code, tax_code, recurring_code, 
					 payment_code, state_flag, paid_flag, recurring_flag, one_time_vend_flag, one_check_flag, accrual_flag, 
					 times_accrued, amt_gross, amt_discount, amt_freight, amt_tax, amt_misc, amt_net, amt_paid_to_date, 
					 amt_tax_included, frt_calc_tax, doc_desc, user_id, journal_ctrl_num, payment_hold_flag, intercompany_flag, 
					 process_ctrl_num, currency_code, rate_type_home, rate_type_oper, rate_home, rate_oper, net_original_amt, org_id,
					 tax_freight_no_recoverable 
				FROM apvohdr_all 
GO
GRANT REFERENCES ON  [dbo].[apvohdr] TO [public]
GO
GRANT SELECT ON  [dbo].[apvohdr] TO [public]
GO
GRANT INSERT ON  [dbo].[apvohdr] TO [public]
GO
GRANT DELETE ON  [dbo].[apvohdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvohdr] TO [public]
GO
