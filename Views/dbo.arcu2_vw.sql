SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[arcu2_vw]
AS

SELECT
	customer_code,
	address_name,
	short_name,
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
	comment=note,
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
	AcctCustomer_ID=ISNULL(ddid,' ')
FROM 	armaster armaster
WHERE 	armaster.address_type = 0

GO
GRANT REFERENCES ON  [dbo].[arcu2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcu2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcu2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcu2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcu2_vw] TO [public]
GO
