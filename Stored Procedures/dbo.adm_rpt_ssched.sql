SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_ssched] @range varchar(8000) = '0=0',
@backorder varchar(255) = '',
@order varchar(1000) = ' ord_list.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @backorder = replace(@backorder,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = 'SELECT distinct 
adm_cust_all.customer_code,   
adm_cust_all.customer_name,   
ord_list.order_no,   
ord_list.order_ext,   
ord_list.line_no,   
ord_list.part_no,   
ord_list.description,   
ord_list.ordered,   
ord_list.shipped,   
ord_list.price,  
ord_list.price_type,   
ord_list.uom,   
orders.status,   
orders.date_entered,   
orders.date_shipped,   
ord_list.location,   
orders.sch_ship_date,   
orders.ship_to_region,   
orders.ship_to_name,   
orders.ship_to_city,   
orders.ship_to_state, 
orders.ship_to 
 FROM orders (nolock), ord_list (nolock), adm_cust_all (nolock), locations l (nolock), region_vw r (nolock),
(select order_no, ext, convert(datetime, convert(varchar(10), sch_ship_date, 1)) from orders o1 (nolock)
 where o1.status between ''N'' and ''Q'' and o1.type = ''I'') o1(order_no,ext,sch_ship_date) 
 WHERE orders.cust_code = adm_cust_all.customer_code and 
      l.location = ord_list.location and 
      l.organization_id = r.org_id and
 orders.order_no = o1.order_no and orders.ext = o1.ext and orders.order_no = ord_list.order_no and 
 orders.ext = ord_list.order_ext and ' + @backorder + @range + '
 ORDER BY ' +  @order
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_ssched] TO [public]
GO
