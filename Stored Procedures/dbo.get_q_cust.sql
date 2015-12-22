SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[get_q_cust] @cust varchar(30), @sort char(1), @void char(1), @mode varchar(2) = '',   -- mls 4/12/00 SCR 21882    
  @secured_mode int = 0, @typ int = 0, @org_id varchar(30) = ''     
AS    
    
-- secured_mode    
-- 0 = unsecured - all customers    
-- 1 = secured - customers for user    
-- 2 = secured and unrelated = customers that are not defined to a customer organization    
-- 3 = secured int/ext = secured with the option of selecting internal or external customers    
    
-- typ = 0 - external vendors    
-- typ = 1 - internal vendors    
-- typ = 2 - BOTH    
    
    
declare @stat int, @minstat int, @sql varchar(4000) 
DECLARE @is_wildcard SMALLINT -- v1.2   
    
select @minstat=case when @void='%' then 0 else 1 end    
select @stat=case when @void='%' then 3 else 1 end    
    
set @secured_mode = isnull(@secured_mode,0)    
    
-- mls 10/29/09 SCR 051825    
if charindex('''', @cust) > 0    
begin    
  select @cust = REPLACE (@cust, "'","''")    
end  

-- START v1.2
IF CHARINDEX('%', @cust) > 0
BEGIN
	SET @is_wildcard = 1 -- true
END
ELSE
BEGIN
	SET @is_wildcard = 0 -- false
END
    
if @typ < '2'    
begin    
select @sql = 'select m.customer_code, customer_name, addr2, m.city, state, contact_phone, territory_code, salesperson_code, status_type , m.postal_code, '    -- v1.1 v1.6
select @sql = @sql + case when @secured_mode < 2 or @typ = 0 then 'NULL' else ' l.customer_org_id' end    
select @sql = @sql + ' from'    
select @sql = @sql + case when @secured_mode in (1,2,3) then ' adm_cust m (nolock)' else ' adm_cust_all m (nolock)' end    
if @secured_mode > 1 and @typ != 0 select @sql = @sql + ' , adm_orglinks_vw l (nolock)'    
select @sql = @sql + ' where'    
select @sql = @sql +     
  case @sort    
    when 'N' then ' m.customer_name'    
    when 'P' then ' m.contact_phone'    
    when 'S' then ' m.salesperson_code'    
    when 'T' then ' m.territory_code'
	when 'Z' then ' m.postal_code'	-- v1.1    
    else ' m.customer_code'    
  end    
-- START v1.2
IF @is_wildcard = 0
BEGIN
	select @sql = @sql + ' >= ''' + @cust + ''''    
END
ELSE
BEGIN
	select @sql = @sql + ' LIKE ''' + @cust + ''''    
END
-- END v1.2
select @sql = @sql + case when (@secured_mode = 3 and @typ = 0) or @secured_mode = 2 then ' and m.related_org_id is NULL' else '' end    
if @void != '%' select @sql = @sql + ' and status_type = 1'    
if @mode = 'oe' select @sql = @sql + ' and valid_soldto_flag = 1'    
if @secured_mode > 1 and @typ = 1 select @sql = @sql + ' and m.customer_code = l.customer_code and l.vendor_org_id = ''' + @org_id + ''''    
select @sql = @sql + ' order by'    
select @sql = @sql +     
  case @sort    
	-- START v1.5
    when 'N' then ' customer_name, m.customer_code'    
    when 'P' then ' contact_phone, m.customer_code'    
    when 'S' then ' salesperson_code, m.customer_code'    
    when 'T' then ' territory_code, m.customer_code'
	when 'Z' then ' m.postal_code, m.customer_code'	-- v1.1    
	-- END v1.5 
    else ' m.customer_code'    
  end    
end    
else    
begin    
select @sql = '  select distinct  m.customer_code, customer_name, addr2, m.city , state, contact_phone, territory_code, salesperson_code, status_type, m.postal_code,  '   -- v1.1 v1.6 v1.7 missing comma
select @sql = @sql + ' case when m.related_org_id is null then NULL else ''' + @org_id + ''' end'    
select @sql = @sql + ' from'    
select @sql = @sql + case when @secured_mode in (1,2,3) then ' adm_cust m (nolock)' else ' adm_cust_all m (nolock)' end    
if @secured_mode > 1 select @sql = @sql + ' , adm_orglinks_vw l (nolock)'    
select @sql = @sql + ' where '    
select @sql = @sql +     
  case @sort    
    when 'N' then ' m.customer_name'    
    when 'P' then ' m.contact_phone'    
    when 'S' then ' m.salesperson_code'    
    when 'T' then ' m.territory_code'
	when 'Z' then ' m.postal_code'	-- v1.1  
    else ' m.customer_code'    
  end    
-- START v1.2
IF @is_wildcard = 0
BEGIN
	select @sql = @sql + ' >= ''' + @cust + ''''    
END
ELSE
BEGIN
	select @sql = @sql + ' LIKE ''' + @cust + ''''    
END
-- END v1.2
select @sql = @sql + case when @secured_mode = 2 then ' and (m.related_org_id is null or (m.customer_code = l.customer_code and l.vendor_org_id = ''' + @org_id + '''))' else '' end    
if @void != '%' select @sql = @sql + ' and status_type = 1'    
if @mode = 'oe' select @sql = @sql + ' and valid_soldto_flag = 1'    
select @sql = @sql + ' order by'    
select @sql = @sql +     
  case @sort    
	-- START v1.5
    when 'N' then ' customer_name, m.customer_code'    
    when 'P' then ' contact_phone, m.customer_code'    
    when 'S' then ' salesperson_code, m.customer_code'    
    when 'T' then ' territory_code, m.customer_code'
	when 'Z' then ' m.postal_code, m.customer_code'	-- v1.1    
	-- END v1.5
    else ' m.customer_code'    
  end    
end  


-- START v1.3  
-- START v1.4
IF @sort IN ('S','T')
--IF @sort = 'T'
-- END v1.4
BEGIN    
	set rowcount 400    
END
ELSE
BEGIN
	set rowcount 100   
END
-- END v1.3
    
print @sql    
exec (@sql)    
GO
GRANT EXECUTE ON  [dbo].[get_q_cust] TO [public]
GO
