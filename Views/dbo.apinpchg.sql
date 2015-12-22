SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[apinpchg]
		AS
			SELECT timestamp, trx_ctrl_num, trx_type, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, 
				po_ctrl_num, vend_order_num, ticket_num, date_applied, date_aging, date_due, date_doc, 
				date_entered, date_received, date_required, date_recurring, date_discount, posting_code, 
				vendor_code, pay_to_code, branch_code, class_code, approval_code, comment_code, fob_code, 
				terms_code, tax_code, recurring_code, location_code, payment_code, times_accrued, accrual_flag, 
				drop_ship_flag, posted_flag, hold_flag, add_cost_flag, approval_flag, recurring_flag, one_time_vend_flag, 
				one_check_flag, amt_gross, amt_discount, amt_tax, amt_freight, amt_misc, amt_net, amt_paid, amt_due, 
				amt_restock, amt_tax_included, frt_calc_tax, doc_desc, hold_desc, user_id, next_serial_id, pay_to_addr1, 
				pay_to_addr2, pay_to_addr3, pay_to_addr4, pay_to_addr5, pay_to_addr6, pay_to_city, pay_to_state, 
					pay_to_postal_code, pay_to_country_code, attention_name, attention_phone, 
				intercompany_flag, company_code, cms_flag, process_group_num, nat_cur_code, rate_type_home, rate_type_oper, 
				rate_home, rate_oper, net_original_amt, org_id, tax_freight_no_recoverable
			 FROM	apinpchg_all 
GO
GRANT REFERENCES ON  [dbo].[apinpchg] TO [public]
GO
GRANT SELECT ON  [dbo].[apinpchg] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpchg] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpchg] TO [public]
GO
