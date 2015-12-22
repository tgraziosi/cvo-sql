SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_loc_al_po_access_view] @typ int, @loc varchar(10), @user varchar(255) AS
set nocount on

declare @sec_loc varchar(10), @org_id varchar(30), @out_loc_org varchar(60)
declare @user_id int, @user_use_sec int, @comp_id int

select @comp_id = company_id from glco (nolock)
select @user_use_sec = 0
select @user_id = user_id from smusers_vw (nolock) where user_name = @user
if @@rowcount <> 0
begin
  select @user_use_sec = write from smperm where app_id = 18000 and user_id = @user_id and company_id = @comp_id and form_id = 16766
end

select @sec_loc = location from locations where location = @loc
select @org_id = organization_id from locations_all where location = @loc

create table #locs (loc_org varchar(30), vendor_code varchar(12), access int)

if @typ = 1 -- vendor
begin
insert #locs
select vendor_org_id, vendor_code, case when o.organization_id is null or @user_use_sec = 0 then 0 else 1 end
from adm_orglinks_vw r
left outer join Organization o (nolock) on r.vendor_org_id = o.organization_id 
where r.customer_org_id = @org_id

select @out_loc_org = isnull((select organization_name from Organization_all where organization_id = @org_id),@org_id)

select @out_loc_org, l.loc_org, vendor_code, access
from #locs l
order by l.loc_org
end

GO
GRANT EXECUTE ON  [dbo].[adm_loc_al_po_access_view] TO [public]
GO
