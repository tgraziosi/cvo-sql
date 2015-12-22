SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_vendor] @vendor varchar(30), @sort char(1), @void char(1), @secured_mode int = 0, @typ int = 0, @org_id varchar(30) = '' AS

declare @sql varchar(4000)

set @org_id = isnull(@org_id,'')
set @secured_mode = isnull(@secured_mode,0)
set @typ = isnull(@typ,0)

-- secured_mode
-- 0 = unsecured - all vendors
-- 1 = secured - vendors for user
-- 2 = secured and unrelated = vendors that are not defined to a vendor organization
-- 3 = secured int/ext = secured with the option of selecting internal or external vendors

-- typ = 0 - external vendors
-- typ = 1 - internal vendors
-- typ = 2 - BOTH

set rowcount 100

if @typ < '2'
begin
select @sql = 
  'select m.vendor_code, m.vendor_name, m.addr2, m.city, m.state'
select @sql = @sql + case when @secured_mode < 2 or @typ = 0 then '' else ', l.vendor_org_id' end
select @sql = @sql + ' from'
select @sql = @sql + case when @secured_mode in (1,2,3) then ' adm_vend m (nolock)' else ' adm_vend_all m (nolock)' end
if @secured_mode > 1 and @typ != 0 select @sql = @sql + ' , adm_orglinks_vw l (nolock)'
select @sql = @sql + ' where status_type <> ''6'' and'
select @sql = @sql + case when @sort = '1' then ' m.vendor_code' else ' m.vendor_name' end
select @sql = @sql + ' >= ''' + @vendor + ''''
select @sql = @sql + case when (@secured_mode = 3 and @typ = 0) or @secured_mode = 2 then ' and m.related_org_id is NULL' else '' end
if @secured_mode > 1 and @typ = 1 select @sql = @sql + ' and m.vendor_code = l.vendor_code and l.customer_org_id = ''' + @org_id + ''''
select @sql = @sql + ' order by'
select @sql = @sql + case when @sort = '1' then ' m.vendor_code' else ' m.vendor_name' end
end
else
begin
select @sql = 
  'select distinct m.vendor_code, m.vendor_name, m.addr2, m.city, m.state, case when m.related_org_id is null then NULL else ''' + @org_id + ''' end
  from'
select @sql = @sql + case when @secured_mode in (1,2,3) then ' adm_vend m (nolock)' else ' adm_vend_all m (nolock)' end
if @secured_mode > 1 select @sql = @sql + ' left outer join adm_orglinks_vw l (nolock) on l.vendor_code = m.vendor_code '
select @sql = @sql + ' where status_type <> ''6'' and'
select @sql = @sql + case when @sort = '1' then ' m.vendor_code' else ' m.vendor_name' end
select @sql = @sql + ' >= ''' + @vendor + ''''
select @sql = @sql + case when @secured_mode = 2 then ' and (m.related_org_id is null or (l.customer_org_id = ''' + @org_id + '''))' else '' end
select @sql = @sql + case when @secured_mode = 3 then ' and isnull(l.customer_org_id,''' + @org_id + ''') = ''' + @org_id + '''' else '' end
select @sql = @sql + ' order by'
select @sql = @sql + case when @sort = '1' then ' m.vendor_code' else ' m.vendor_name' end
end
print @sql
exec (@sql)

GO
GRANT EXECUTE ON  [dbo].[get_q_vendor] TO [public]
GO
