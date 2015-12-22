SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[atapvend]
AS
SELECT
	timestamp,
	vendor_code,
	vendor_name = address_name,
	vendor_short_name = short_name,
	addr1,
	addr2,
	addr3,
	addr4,
	addr5,
	addr6,
	addr_sort1,
	addr_sort2,
	addr_sort3,
	status_type,
	attention_name,
	attention_phone,
	contact_name,
	contact_phone,
	tlx_twx,
	phone_1,
	phone_2,
	pay_to_code,
 	 
	tax_code,
	
	terms_code,
	fob_code,
	posting_code,
	location_code,
	orig_zone_code,
	customer_code,
	affiliated_vend_code,
	alt_vendor_code,
	comment_code,
	vend_class_code,	
	branch_code,
	pay_to_hist_flag,
	item_hist_flag,
	credit_limit_flag,
	credit_limit,
	aging_limit_flag,
	aging_limit,
	restock_chg_flag,
	restock_chg,
	prc_flag,
	vend_acct,
	tax_id_num,
	flag_1099,
	exp_acct_code,
	amt_max_check,
	lead_time,
	one_check_flag,
	dup_voucher_flag,
	dup_amt_flag,
	code_1099,
	user_trx_type_code,
	payment_code,
	address_type,
    limit_by_home,
    rate_type_home,
    rate_type_oper,
    nat_cur_code,
    one_cur_vendor,
	cash_acct_code,
	city,
	state,
	postal_code,
	country,
	freight_code,
	note,
	url,



	country_code,



	ftp,
	attention_email,
	contact_email,
        etransmit_ind,



	po_item_flag,
	vo_hold_flag,
	buying_cycle,

	at_tax_code_flag,
	at_tax_code,
        voprocs_amount_acc_expense,	
	at_usevendor_prorate_setting,
 	tax_flag,
	tax_per_1line_2qty_3amt,
	freight_flag,
	freight_per_1line_2qty_3amt,
	disc_flag,
	disc_per_1line_2qty_3amt,
	misc_flag,
        misc_per_1line_2qty_3amt
	
        
FROM apmaster_all
WHERE vendor_code IN (SELECT vendor_code FROM sm_vendors_access_vw)
      AND address_type = 0
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[atapvend] TO [public]
GO
GRANT SELECT ON  [dbo].[atapvend] TO [public]
GO
GRANT INSERT ON  [dbo].[atapvend] TO [public]
GO
GRANT DELETE ON  [dbo].[atapvend] TO [public]
GO
GRANT UPDATE ON  [dbo].[atapvend] TO [public]
GO
