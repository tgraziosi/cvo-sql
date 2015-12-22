SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[apvnd_vw]
AS
SELECT
	timestamp,
	vendor_code,
	pay_to_code,
	pay_to_name = address_name,
	pay_to_short_name = short_name,
	addr1,
	addr2,
	addr3,
	addr4,
	addr5,
	addr6,
	city,
	state,
	postal_code,
	country_code,
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
	posting_code,
	location_code,
	orig_zone_code,
	note,
	url,
	address_type,
	flag_1099,
	tax_id_num,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	one_cur_vendor
FROM apmaster
WHERE address_type = 1
OR address_type = 2

GO
GRANT REFERENCES ON  [dbo].[apvnd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvnd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvnd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvnd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvnd_vw] TO [public]
GO
