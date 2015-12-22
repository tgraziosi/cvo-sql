SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_ordent] @range varchar(8000) = '0=0',
@ord_status varchar(1000) = '',
@order varchar(1000) = ' orders.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @ord_status = replace(@ord_status,'"','''')
select @order = replace(@order,'"','''')


declare @sql varchar(8000)

select @sql = '
SELECT distinct 
adm_cust_all.customer_code,  
adm_cust_all.customer_name, 
ord_list.order_no, 
ord_list.order_ext, 
ord_list.line_no, 
ord_list.part_type, 
ord_list.part_no, 
ord_list.description, 
ord_list.ordered, 
ord_list.shipped, 
ord_list.curr_price, 
ord_list.price_type, 
ord_list.uom, 
ord_list.location, 
orders.status, 
orders.date_entered, 
orders.date_shipped, 
orders.sch_ship_date, 
glcurr_vw.symbol, 
glcurr_vw.curr_precision, 
orders.invoice_no 
 FROM  adm_cust_all (nolock), orders (nolock), ord_list (nolock), glcurr_vw (nolock), 
   locations l (nolock), region_vw r (nolock)
 WHERE 
   l.location = ord_list.location and 
   l.organization_id = r.org_id and
( orders.order_no = ord_list.order_no ) and 
( orders.ext = ord_list.order_ext ) and 
( orders.cust_code = adm_cust_all.customer_code ) and 
( orders.type = ''I'' ) and  
( orders.curr_key = glcurr_vw.currency_code) and ' + @ord_status + @range + ' 
 ORDER BY ' + @order
			
print @sql
exec (@sql)
									
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_ordent] TO [public]
GO
