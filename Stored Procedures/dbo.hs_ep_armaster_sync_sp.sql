SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[hs_ep_armaster_sync_sp]
as 
begin

update c set c.contact_name = h.contact_name
-- select * 
from hs_armaster_sync_tbl h inner join arcust c on c.customer_code = h.customer_code
where h.contact_name is not null and c.contact_name <> h.contact_name

update c set c.contact_phone = h.contact_phone
-- select * 
from hs_armaster_sync_tbl h inner join arcust c on c.customer_code = h.customer_code
where h.contact_phone is not null and h.contact_phone <> c.contact_phone

update c set c.tlx_twx = h.tlx_twx
-- select * 
from hs_armaster_sync_tbl h inner join arcust c on c.customer_code = h.customer_code
where h.tlx_twx is not null and h.tlx_twx <> c.tlx_twx

update c set c.contact_email = h.contact_email
-- select * 
from hs_armaster_sync_tbl h inner join arcust c on c.customer_code = h.customer_code
where h.contact_email is not null and h.contact_email <> c.contact_email

truncate table hs_armaster_sync_tbl

end
GO
GRANT EXECUTE ON  [dbo].[hs_ep_armaster_sync_sp] TO [public]
GO
