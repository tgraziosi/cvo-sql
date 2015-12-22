SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[artrx]
			AS
			  SELECT timestamp, doc_ctrl_num, trx_ctrl_num, apply_to_num, apply_trx_type, order_ctrl_num, doc_desc, 
				batch_code, trx_type, date_entered, date_posted, date_applied, date_doc, date_shipped, date_required,
				 date_due, date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, payment_code, payment_type, cust_po_num, non_ar_flag, gl_acct_code, gl_trx_id, prompt1_inp, prompt2_inp, 
				prompt3_inp, prompt4_inp, deposit_num, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_paid_to_date,
				 amt_net, amt_on_acct, amt_cost, amt_tot_chg, user_id, void_flag, paid_flag, date_paid, posted_flag, commission_flag, 
				cash_acct_code, non_ar_doc_num, purge_flag, process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, 
				amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, reference_code, ddid, org_id 
			  FROM artrx_all 
GO
GRANT REFERENCES ON  [dbo].[artrx] TO [public]
GO
GRANT SELECT ON  [dbo].[artrx] TO [public]
GO
GRANT INSERT ON  [dbo].[artrx] TO [public]
GO
GRANT DELETE ON  [dbo].[artrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrx] TO [public]
GO
