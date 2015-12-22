SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[locations_hdr_vw]
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
valid.module,
o.io_use_po_ind,
o.io_use_so_ind,
o.io_use_xfer_ind,
o.io_create_po_ind,
o.io_create_so_ind,
o.use_ext_vend_ind,
l.city,
l.state,
l.zip,
1 as curr_org_ind
from locations_all l (nolock)
--join adm_locs_with_access_vw s (nolock) on s.location = l.location
left outer join adm_organization o (nolock) on l.organization_id = o.organization_id
join (
select  'po' module 
 UNION
select  'cm' module 
 UNION
select  'soe' module 
UNION
select  'match' module 
UNION
select  'xfr' module 
) as valid ( module) on 1=1
GO
GRANT SELECT ON  [dbo].[locations_hdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[locations_hdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[locations_hdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[locations_hdr_vw] TO [public]
GO
