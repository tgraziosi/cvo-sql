SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[arinpchg]
			AS
			  SELECT timestamp, trx_ctrl_num, doc_ctrl_num, doc_desc, apply_to_num, apply_trx_type, order_ctrl_num, 
				batch_code, trx_type, date_entered, date_applied, date_doc, date_shipped, date_required, date_due, 
				date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, cust_po_num, total_weight, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_net, 
				amt_paid, amt_due, amt_cost, amt_profit, next_serial_id, printed_flag, posted_flag, hold_flag, hold_desc, user_id, 
				customer_addr1, customer_addr2, customer_addr3, customer_addr4, customer_addr5, customer_addr6,  customer_city, customer_state, 
				customer_postal_code, customer_country_code, ship_to_addr1, 
				ship_to_addr2, ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6,
				ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, 
				attention_name, attention_phone, 
				amt_rem_rev, amt_rem_tax, date_recurring, location_code, process_group_num, source_trx_ctrl_num, source_trx_type, 
				amt_discount_taken, amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, 
				edit_list_flag, ddid, writeoff_code, vat_prc, org_id 
			  FROM arinpchg_all 
GO
GRANT REFERENCES ON  [dbo].[arinpchg] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpchg] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpchg] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpchg] TO [public]
GO
