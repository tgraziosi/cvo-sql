SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_q_organization] @cust varchar(30), @sort char(1), @secured_mode int = 0 AS

declare @sql varchar(1000)

select @sql = 'select distinct org_id, organizationname'

if @secured_mode = 1
begin
  select @sql = @sql + ' from organization_vw ( NOLOCK ), locations (nolock)'
  select @sql = @sql + ' where organization_vw.organization_id = locations.organization_id'
end
else
begin
  select @sql = @sql + ' from organization_vw ( NOLOCK )'
  select @sql = @sql + ' where active_flag = 1'								-- CVO FIX TM 21-SEP-2011
end
set rowcount 100

if @sort='L'
begin
select @sql = @sql + ' and org_id >= ''' + @cust + ''''
select @sql = @sql + ' order by org_id'

exec (@sql)
end
if @sort='N'
begin
select @sql = @sql + ' and organizationname >= ''' + @cust + ''''
select @sql = @sql + ' order by organizationname'

exec (@sql)
end


GO
GRANT EXECUTE ON  [dbo].[get_q_organization] TO [public]
GO
