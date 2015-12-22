SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                






































CREATE VIEW	[dbo].[apvendok_vw]
AS


SELECT vendor_code, vendor_name, vendor_short_name, addr1, addr2, addr3, addr4, addr5, addr6, addr_sort1, addr_sort2, addr_sort3, 
status_type, attention_name, attention_phone, contact_name, contact_phone, tlx_twx, phone_1, phone_2, pay_to_code, 
			ISNULL(Case (select ib_flag from glco)
				When 1
				Then  (	SELECT 	CASE LEN(ap.tax_code) WHEN 0 THEN apvend.tax_code ELSE ap.tax_code END
					FROM	ap_vendor_org_defaults ap, smspiduser_vw sm 
					WHERE 	sm.spid 	= @@spid
					AND 	sm.org_id 	= ap.organization_id
					AND 	ap.vendor_code = apvend.vendor_code 
					) 
			end, tax_code) as tax_code,
			ISNULL(Case (select ib_flag from glco)
				When 1
				Then  (	SELECT 	CASE LEN(ap.terms_code) WHEN 0 THEN apvend.terms_code ELSE ap.terms_code END
					FROM	ap_vendor_org_defaults ap, smspiduser_vw sm 
					WHERE 	sm.spid 	= @@spid
					AND 	sm.org_id 	= ap.organization_id
					AND 	ap.vendor_code = apvend.vendor_code 
					) 
			end, terms_code) as terms_code,
fob_code, 		ISNULL(Case (select ib_flag from glco)
				When 1
				Then  (	SELECT 	CASE LEN(ap.posting_code) WHEN 0 THEN apvend.posting_code ELSE ap.posting_code END
					FROM	ap_vendor_org_defaults ap, smspiduser_vw sm 
					WHERE 	sm.spid 	= @@spid
					AND 	sm.org_id 	= ap.organization_id
					AND 	ap.vendor_code = apvend.vendor_code 
					) 
			end, posting_code) as posting_code,
location_code, orig_zone_code, customer_code, affiliated_vend_code, alt_vendor_code, comment_code, vend_class_code, branch_code, 
pay_to_hist_flag, item_hist_flag, credit_limit_flag, credit_limit, aging_limit_flag, aging_limit, restock_chg_flag, restock_chg, 
prc_flag, vend_acct, tax_id_num, flag_1099, exp_acct_code, amt_max_check, lead_time, one_check_flag, dup_voucher_flag, dup_amt_flag, 
code_1099, user_trx_type_code, payment_code, address_type, limit_by_home, rate_type_home, rate_type_oper, nat_cur_code, one_cur_vendor, 
			ISNULL(Case (select ib_flag from glco)
				When 1
				Then  (	SELECT 	CASE LEN(ap.cash_acct_code) WHEN 0 THEN apvend.cash_acct_code ELSE ap.cash_acct_code END
					FROM	ap_vendor_org_defaults ap, smspiduser_vw sm 
					WHERE 	sm.spid 	= @@spid
					AND 	sm.org_id 	= ap.organization_id
					AND 	ap.vendor_code = apvend.vendor_code 
					) 
			end, cash_acct_code) as cash_acct_code,
city, state, postal_code, country, freight_code, note, url, country_code, ftp, 
attention_email, contact_email, etransmit_ind, po_item_flag, vo_hold_flag, buying_cycle, proc_vend_flag
FROM 	apvend
WHERE		status_type = 5
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apvendok_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvendok_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvendok_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvendok_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvendok_vw] TO [public]
GO
