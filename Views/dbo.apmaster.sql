SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[apmaster]
				AS
				SELECT timestamp, vendor_code, pay_to_code, address_name, short_name, 
					addr1, addr2, addr3, addr4, addr5, addr6, addr_sort1, addr_sort2, addr_sort3, 
					address_type, status_type, attention_name, attention_phone, contact_name, contact_phone, 
					tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, posting_code, location_code, 
					orig_zone_code, customer_code, affiliated_vend_code, alt_vendor_code, comment_code, vend_class_code,
					branch_code, pay_to_hist_flag, item_hist_flag, credit_limit_flag, credit_limit, aging_limit_flag, 
					aging_limit, restock_chg_flag, restock_chg, prc_flag, vend_acct, tax_id_num, flag_1099, exp_acct_code,
					amt_max_check, lead_time, doc_ctrl_num, one_check_flag, dup_voucher_flag, dup_amt_flag, code_1099, 
					user_trx_type_code, payment_code, limit_by_home, rate_type_home, rate_type_oper, nat_cur_code, one_cur_vendor,
					cash_acct_code, city, state, postal_code, country, freight_code, url, note, country_code, ftp, attention_email, 
					contact_email, etransmit_ind, vo_hold_flag, po_item_flag, buying_cycle, proc_vend_flag, extended_name, check_extendedname_flag 
				FROM apmaster_all 
GO
GRANT REFERENCES ON  [dbo].[apmaster] TO [public]
GO
GRANT SELECT ON  [dbo].[apmaster] TO [public]
GO
GRANT INSERT ON  [dbo].[apmaster] TO [public]
GO
GRANT DELETE ON  [dbo].[apmaster] TO [public]
GO
GRANT UPDATE ON  [dbo].[apmaster] TO [public]
GO
