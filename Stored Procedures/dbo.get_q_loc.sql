SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_q_loc] @cust varchar(30), @sort char(1), @void char(1), @secured_mode int = 1,
  @controlling_org varchar(30) = '' , @module varchar(10) = '', @sec_level int = 0 AS

set rowcount 100
if @secured_mode = 1
begin
  if isnull(@controlling_org,'') <> '' 
  begin
    if @sort='L'
    begin
    select location, name, addr1, addr2, addr3, organization_id
    from locations ( NOLOCK ) where location >= @cust and 
    location in (select location from dbo.adm_get_related_locs_fn (@module,@controlling_org,@sec_level)) and 
    (void is NULL OR void like @void) 
    order by location
    end
    if @sort='N'
    begin
    select location, name, addr1, addr2, addr3, organization_id
    from locations ( NOLOCK ) where name >= @cust and 						-- mls 11/29/00 SCR 25116
    location in (select location from dbo.adm_get_related_locs_fn (@module,@controlling_org,@sec_level)) and 
    (void is NULL OR void like @void)
    order by name
    end
  end
  else
  begin
    if @sort='L'
    begin
      select location, name, addr1, addr2, addr3, organization_id
      from locations ( NOLOCK ) where location >= @cust and 
      (void is NULL OR void like @void) 
      order by location
    end
    if @sort='N'
    begin
      select location, name, addr1, addr2, addr3, organization_id
      from locations ( NOLOCK ) where name >= @cust and 						-- mls 11/29/00 SCR 25116
      (void is NULL OR void like @void)
      order by name
    end
  end
  return
end
if @secured_mode = 2 -- only header orgs
begin
  if @sort='L'
  begin
    select location, name, addr1, addr2, addr3, organization_id
    from locations_hdr_vw ( NOLOCK ) where location >= @cust and module = @module and
    (void is NULL OR void like @void) and (@sec_level > 0 or organization_id = dbo.sm_get_current_org_fn())
    order by location
  end
  if @sort='N'
  begin
    select location, name, addr1, addr2, addr3, organization_id
    from locations_hdr_vw ( NOLOCK ) where name >= @cust and 						-- mls 11/29/00 SCR 25116
    (void is NULL OR void like @void)  and module = @module
     and (@sec_level > 0 or organization_id = dbo.sm_get_current_org_fn())
    order by name
  end
  return
end

if @sort='L'
begin
select location, name, addr1, addr2, addr3, organization_id
from locations_all ( NOLOCK ) where location >= @cust and 
(void is NULL OR void like @void) 
order by location
end
if @sort='N'
begin
select location, name, addr1, addr2, addr3, organization_id
from locations_all ( NOLOCK ) where name >= @cust and 						-- mls 11/29/00 SCR 25116
(void is NULL OR void like @void)
order by name
end


GO
GRANT EXECUTE ON  [dbo].[get_q_loc] TO [public]
GO
