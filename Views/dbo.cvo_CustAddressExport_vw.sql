SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- Author = E.L.
-- 071812 - tag - create view for EV
-- select * from cvo_CustAddressExport_vw
CREATE view [dbo].[cvo_CustAddressExport_vw] 
as
select 
case status_type when 1 then 'Active'
	when 2 then 'NoNewBus'
	else 'INActive' END as Status, 
territory_code as Territory, salesperson_code as Salesperson,
Contact_name as contact, Customer_code, Ship_to_code, address_name as Customer_Name, 
addr2 as Address1, addr3 as Address2, addr4 as Address4,
CITY, STATE, postal_code as ZIP, 
country_code as COUNTRY, contact_PHONE as Phone, tlx_twx as FAX, contact_EMAIL, Attention_email, 	STATUS_TYPE
from armaster
where address_type <>9
--order by territory_code, status_type, customer_code


GO
GRANT SELECT ON  [dbo].[cvo_CustAddressExport_vw] TO [public]
GO
