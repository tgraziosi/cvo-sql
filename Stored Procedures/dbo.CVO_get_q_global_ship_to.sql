SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
CREATE PROCEDURE [dbo].[CVO_get_q_global_ship_to] @cust varchar(30), @sort char(1), @void char(1), @mode varchar(2) = '',   -- mls 4/12/00 SCR 21882    
  @secured_mode int = 0, @typ int = 0, @org_id varchar(30) = ''     
AS    
BEGIN    
-- v1.0 CB 07/08/2013 - Issue #1111 - Remove org and add city
-- secured_mode    
-- 0 = unsecured - all customers    
-- 1 = secured - customers for user    
-- 2 = secured and unrelated = customers that are not defined to a customer organization    
-- 3 = secured int/ext = secured with the option of selecting internal or external customers    
    
-- typ = 0 - external vendors    
-- typ = 1 - internal vendors    
-- typ = 2 - BOTH    
    
    
declare @stat int, @minstat int, @sql varchar(4000)    
    
select @minstat=case when @void='%' then 0 else 1 end    
select @stat=case when @void='%' then 3 else 1 end    
    
set @secured_mode = isnull(@secured_mode,0)    
    
-- mls 10/29/09 SCR 051825    
if charindex('''', @cust) > 0    
begin    
  select @cust = REPLACE (@cust, '''','''''')    
end    
    
if @typ < '2'    
begin    
select @sql = 'select m.customer_code, customer_name, addr2, m.city, state, contact_phone, territory_code, salesperson_code, status_type ,'  -- v1.0  
select @sql = @sql + case when @secured_mode < 2 or @typ = 0 then 'NULL' else ' l.customer_org_id' end    
select @sql = @sql + ' from'    
select @sql = @sql + case when @secured_mode in (1,2,3) then ' adm_global_shipto_vw m (nolock)' else ' adm_global_shipto_all_vw m (nolock)' end    
if @secured_mode > 1 and @typ != 0 select @sql = @sql + ' , adm_orglinks_vw l (nolock)'    
select @sql = @sql + ' where address_type=9 AND'    
select @sql = @sql +     
  case @sort    
    when 'N' then ' m.customer_name'    
    when 'P' then ' m.contact_phone'    
    when 'S' then ' m.salesperson_code'    
    when 'T' then ' m.territory_code'    
    else ' m.customer_code'    
  end    
select @sql = @sql + ' >= ''' + @cust + ''''    
select @sql = @sql + case when (@secured_mode = 3 and @typ = 0) or @secured_mode = 2 then ' and m.related_org_id is NULL' else '' end    
if @void != '%' select @sql = @sql + ' and status_type = 1'    
--if @mode = 'oe' select @sql = @sql + ' and valid_soldto_flag = 1'    
if @secured_mode > 1 and @typ = 1 select @sql = @sql + ' and m.customer_code = l.customer_code and l.vendor_org_id = ''' + @org_id + ''''    
select @sql = @sql + ' order by'    
select @sql = @sql +     
  case @sort    
    when 'N' then ' m.customer_name'    
    when 'P' then ' m.contact_phone'    
    when 'S' then ' m.salesperson_code'    
    when 'T' then ' m.territory_code'    
    else ' m.customer_code'    
  end    
end    
else    
begin    
select @sql = '  select distinct  m.customer_code, customer_name, addr2,  m.city, state, contact_phone, territory_code, salesperson_code, status_type, '    
select @sql = @sql + ' case when m.related_org_id is null then NULL else ''' + @org_id + ''' end'    
select @sql = @sql + ' from'    
select @sql = @sql + case when @secured_mode in (1,2,3) then ' adm_global_shipto_vw m (nolock)' else ' adm_global_shipto_all_vw m (nolock)' end    
if @secured_mode > 1 select @sql = @sql + ' , adm_orglinks_vw l (nolock)'    
select @sql = @sql + ' where address_type=9 AND'    
select @sql = @sql +     
  case @sort    
    when 'N' then ' customer_name'    
    when 'P' then ' contact_phone'    
    when 'S' then ' salesperson_code'    
    when 'T' then ' territory_code'    
    else ' m.customer_code'    
  end    
select @sql = @sql + ' >= ''' + @cust + ''''    
select @sql = @sql + case when @secured_mode = 2 then ' and (m.related_org_id is null or (m.customer_code = l.customer_code and l.vendor_org_id = ''' + @org_id + '''))' else '' end    
if @void != '%' select @sql = @sql + ' and status_type = 1'    
--if @mode = 'oe' select @sql = @sql + ' and valid_soldto_flag = 1'    
select @sql = @sql + ' order by'    
select @sql = @sql +     
  case @sort    
    when 'N' then ' customer_name'    
    when 'P' then ' contact_phone'    
    when 'S' then ' salesperson_code'    
    when 'T' then ' territory_code'    
    else ' m.customer_code'    
  end    
end    
    
set rowcount 100    
    
print @sql    
exec (@sql)    
END  
GO
GRANT EXECUTE ON  [dbo].[CVO_get_q_global_ship_to] TO [public]
GO
