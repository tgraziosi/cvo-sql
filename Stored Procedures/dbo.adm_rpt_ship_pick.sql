SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_rpt_ship_pick] 
@loc varchar(10),
@cust varchar(10),
@ord int,
@ext int,
@loadno int,
@schdate int,
@minstat char(1),
@maxstat char(1),
@ship_to varchar(10),
@backorder varchar(20),
@pcppf int,
@org_id varchar(30),
@secured_mode int
AS
begin

declare @sql varchar(2000)

if isnull(@ship_to,'') = ''
  set @ship_to = '%'

select @sql =  'SELECT DISTINCT orders.order_no, orders.ext, orders.location, orders.sch_ship_date, orders.req_ship_date,'   
select @sql = @sql + ' orders.cust_code, orders.status _good, cust.customer_name, orders.status,   '' '' _printstatus,'
select @sql = @sql + ' orders.who_entered, ' + convert(varchar,@pcppf) + ' pcppf, ''' + @loc + ''',''' + @org_id + ''''
if @secured_mode = 0
begin
  select @sql = @sql + ' FROM orders_shipping_vw orders,  adm_cust_all cust,'
  if @ship_to != '%' select @sql = @sql + ' adm_shipto_all shipto,'
end
else
begin
  select @sql = @sql + ' FROM orders_entry_vw orders,  adm_cust cust,'
  if @ship_to != '%' select @sql = @sql + ' adm_shipto shipto,'
end

select @sql = @sql + ' ord_list_ship_vw'
select @sql = @sql + ' WHERE (orders.cust_code = cust.customer_code ) '
select @sql = @sql + ' and (orders.order_no = ord_list_ship_vw.order_no and orders.ext = ord_list_ship_vw.order_ext)'
select @sql = @sql + ' and (orders.status between ''' + @minstat + ''' AND ''' + @maxstat + ''') '
select @sql = @sql + ' and not exists (select 1 from load_master lm (nolock) where lm.load_no = orders.load_no and lm.status in (''H'',''C'')) '
select @sql = @sql + ' and (dbo.adm_get_pltdate_f(orders.sch_ship_date) <= ''' + convert(varchar,@schdate) + ''')  '
select @sql = @sql + ' and (orders.type = ''I'')  '
select @sql = @sql + ' and (ord_list_ship_vw.location not like ''DROP%'') and ord_list_ship_vw.protect_line = 0  '
select @sql = @sql + ' and (ord_list_ship_vw.printed_dt is NULL)'
select @sql = @sql + ' and (orders.printed <= orders.status) '

if @ship_to != '%' select @sql = @sql + ' and ( orders.cust_code = shipto.customer_code) AND ( orders.ship_to = shipto.ship_to_code)'
if @ship_to != '%' select @sql = @sql + ' and ( shipto.ship_to_code like ''' + @ship_to + ''' )'
if @org_id != '%' select @sql = @sql + ' and ord_list_ship_vw.location in (select location from locations_all (nolock) where isnull(organization_id,'''') = ''' + @org_id + ''')'
if @loc != '%' select @sql = @sql + ' and ord_list_ship_vw.location like ''' + @loc + ''''
if @cust != '%' select @sql = @sql + ' and (orders.cust_code like ''' + @cust + ''')'
if @ord != 0 select @sql = @sql + 'and (orders.order_no = ' + convert(varchar,@ord) + ' AND orders.ext = ' + convert(varchar,@ext) + ')  '
if @loadno != 0 select @sql = @sql + ' and (orders.load_no = ' + convert(varchar,@loadno) + ')  '
if @backorder != '%' select @sql = @sql + ' AND	(( orders.who_entered like ''' + @backorder + ''' ))'

select @sql = @sql + ' ORDER BY orders.location ASC,  orders.sch_ship_date ASC, orders.order_no ASC, orders.ext ASC '

print @sql
exec (@sql)
end

GO
GRANT EXECUTE ON  [dbo].[adm_rpt_ship_pick] TO [public]
GO
