SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[locations]
AS
select 
l.timestamp,
l.location,
name,
location_type,
addr1,
addr2,
addr3,
addr4,
addr5,
addr_sort1,
addr_sort2,
addr_sort3,
phone,
contact_name,
consign_customer_code,
consign_vendor_code,
aracct_code,
zone_code,
void,
void_who,
void_date,
note,
apacct_code,
dflt_recv_bin,
country_code,
harbour,
bundesland,
department,
l.organization_id,
city,
state,
zip
from locations_all l
GO
GRANT SELECT ON  [dbo].[locations] TO [public]
GO
GRANT INSERT ON  [dbo].[locations] TO [public]
GO
GRANT DELETE ON  [dbo].[locations] TO [public]
GO
GRANT UPDATE ON  [dbo].[locations] TO [public]
GO
