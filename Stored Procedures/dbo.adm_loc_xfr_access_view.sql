SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_loc_xfr_access_view] @typ int, @loc varchar(10), @user varchar(255) AS
set nocount on

declare @sec_loc varchar(10), @org_id varchar(30), @out_loc_org varchar(60)
declare @user_id int, @user_use_sec int, @comp_id int

select @comp_id = company_id from glco (nolock)
select @user_use_sec = 0
select @user_id = user_id from smusers_vw (nolock) where user_name = @user
if @@rowcount <> 0
begin
  select @user_use_sec = write from smperm where app_id = 18000 and user_id = @user_id and company_id = @comp_id and form_id = 16763
end

select @sec_loc = location from locations where location = @loc
select @org_id = organization_id from locations_all where location = @loc

create table #locs (loc_org varchar(30), org_id varchar(30), create_for_loc int, use_for_loc int, loc_create_for int, loc_use_for int,
access int)

if @typ = 1 -- do for loc
begin

insert #locs
select related_org_id,related_org_id, 0,
case when (@user_use_sec = 0 and related_org_id <> @org_id) or o.organization_id is null then 2 else 1 end,0,0,
case when o.organization_id is null or @sec_loc is null then 0 else 1 end
from adm_xfr_locorgrel_vw r
left outer join Organization o (nolock) on r.related_org_id = o.organization_id
where location = @loc and use_ind = 1
and (related_org_id not in (select organization_id from adm_organization where io_use_xfer_ind = 0)
or related_org_id in (select organization_id from locations_all where location = @loc))

set @out_loc_org = @loc

select @out_loc_org, l.loc_org, org_id, access, sum(create_for_loc), sum(use_for_loc), sum(loc_create_for), sum(loc_use_for)
from #locs l
group by l.loc_org, org_id, access
order by l.loc_org
end

if @typ = 2 -- org can do for
begin

insert #locs
select location,r.organization_id, 0,0,0,
case when (@user_use_sec = 0 and r.organization_id <> @org_id) or o.organization_id is null or @sec_loc is NULL then 2 else 1 end,
case when o.organization_id is null or @sec_loc is null then 0 else 1 end
from adm_xfr_locorgrel_vw r
left outer join Organization o (nolock) on r.organization_id = o.organization_id
where related_org_id = @org_id and use_ind = 1
and (related_org_id not in (select organization_id from adm_organization where io_use_xfer_ind = 0)
or related_org_id = r.organization_id)

select @out_loc_org = isnull((select organization_name from Organization_all where organization_id = @org_id),@org_id)

select @out_loc_org, l.loc_org, org_id, access, sum(create_for_loc), sum(use_for_loc), sum(loc_create_for), sum(loc_use_for)
from #locs l
group by l.loc_org, org_id, access
order by l.loc_org
end

GO
GRANT EXECUTE ON  [dbo].[adm_loc_xfr_access_view] TO [public]
GO
