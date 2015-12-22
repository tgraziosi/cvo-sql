SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cvo_cust_info_vw] as 

select ar.customer_code
, ar.ship_to_code
, ar.address_name
-- , ar.addr1
, ar.addr2
,ar.addr3
,ar.addr4
,ar.addr5
,ar.city
,ar.state
,ar.postal_code
,ar.country_code
,ar.addr_sort1 cust_type
,case ar.status_type when 1 then 'Active'
	when 2 then 'In-Active'
	when 3 then 'NoNewBusiness'
	else 'unknown' end as Status_type
,ar.contact_name
,ar.contact_phone
,ar.contact_email
,ar.tlx_twx Contact_fax
--,ar.phone_1
--,ar.phone_2
,ar.terms_code
,ar.territory_code
,ar.salesperson_code
,ar.price_code
,ar.price_level
,dbo.adm_format_pltdate_f(date_opened) date_opened
,ar.modified_by_date
,car.coop_eligible
,car.door
from armaster ar (nolock) 
inner join cvo_armaster_all car (nolock) 
on ar.customer_code = car.customer_code and ar.ship_to_code = car.ship_to

GO
GRANT REFERENCES ON  [dbo].[cvo_cust_info_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cust_info_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_info_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cust_info_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_info_vw] TO [public]
GO
