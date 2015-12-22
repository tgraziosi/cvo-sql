SET QUOTED_IDENTIFIER ON
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


CREATE VIEW [dbo].[arcust]
AS
SELECT
	timestamp,
	customer_code,
	customer_name = address_name,
	customer_short_name = short_name,
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
	ship_to_code,
	tax_code,
	terms_code,
	fob_code,
	freight_code,
	posting_code,
	location_code,
	alt_location_code,
	dest_zone_code,
	territory_code,
	salesperson_code,
	fin_chg_code,
	price_code,
	payment_code,
	vendor_code,
	affiliated_cust_code,
	print_stmt_flag,
	stmt_cycle_code,
	inv_comment_code,
	stmt_comment_code,
	dunn_message_code,
	note,
	trade_disc_percent,
	invoice_copies,
	iv_substitution,
	ship_to_history,
	check_credit_limit,
	credit_limit,
	check_aging_limit,
	aging_limit_bracket,
	bal_fwd_flag,
	ship_complete_flag,
	resale_num,
	db_num,
	db_date,
	db_credit_rating,
	address_type,
	late_chg_type,
	valid_payer_flag,
	valid_soldto_flag,
	valid_shipto_flag,
	payer_soldto_rel_code,
	across_na_flag,
	date_opened,
	rate_type_home,
	rate_type_oper,
	limit_by_home,
	nat_cur_code,
	one_cur_cust,
	added_by_user_name,
	added_by_date,
	modified_by_user_name,
	modified_by_date,
	city,
	state,
	postal_code,
	country,
	remit_code,
	forwarder_code,
	freight_to_code,
	route_code,
	route_no,
	url,
	special_instr,
	guid,
	price_level,
    ship_via_code,



  so_priority_code,


	country_code,
	tax_id_num,



	ftp,
	attention_email,
	contact_email,
	dunning_group_id,



	consolidated_invoices,
	writeoff_code,




	delivery_days,
	extended_name,
	check_extendedname_flag
FROM armaster nolock
WHERE address_type = 0
/**/                                              

GO
GRANT REFERENCES ON  [dbo].[arcust] TO [public]
GO
GRANT SELECT ON  [dbo].[arcust] TO [public]
GO
GRANT INSERT ON  [dbo].[arcust] TO [public]
GO
GRANT DELETE ON  [dbo].[arcust] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcust] TO [public]
GO
