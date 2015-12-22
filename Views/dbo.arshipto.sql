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





























CREATE VIEW [dbo].[arshipto]
AS
SELECT
	timestamp,
	customer_code,
	ship_to_code,
	ship_to_name = address_name,
	ship_to_short_name = short_name,
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
	note,
	address_type,
	rate_type_home,
	rate_type_oper,
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
FROM armaster
WHERE address_type = 1
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arshipto] TO [public]
GO
GRANT SELECT ON  [dbo].[arshipto] TO [public]
GO
GRANT INSERT ON  [dbo].[arshipto] TO [public]
GO
GRANT DELETE ON  [dbo].[arshipto] TO [public]
GO
GRANT UPDATE ON  [dbo].[arshipto] TO [public]
GO
