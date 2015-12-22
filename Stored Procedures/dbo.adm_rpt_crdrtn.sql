SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_crdrtn] @range varchar(8000) = '0=0',
@crstat varchar(255) = '',
@order varchar(1000) = ' orders.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @crstat = replace(@crstat,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = 'SELECT distinct  adm_cust_all.customer_code,    
adm_cust_all.customer_name,    
ord_list.order_no,    
ord_list.order_ext,    
ord_list.line_no,    
ord_list.part_no,    
ord_list.description,    
ord_list.discount,    
ord_list.shipped,    
ord_list.price,    
ord_list.price_type,    
ord_list.uom,    
orders.status,    
orders.date_entered,    
orders.date_shipped,    
ord_list.location,    
ord_list.cr_ordered,    
ord_list.cr_shipped,    
ord_list.reason_code    
FROM adm_cust_all (nolock), ord_list (nolock), orders (Nolock), locations l (nolock), region_vw r (nolock)
WHERE ( adm_cust_all.customer_code = orders.cust_code ) and   
   l.location = ord_list.location and 
   l.organization_id = r.org_id and
( orders.order_no = ord_list.order_no ) and   
( orders.ext = ord_list.order_ext ) and 
( ord_list.cr_shipped > 0 or ord_list.cr_ordered > 0) and ' + @crstat + @range + '
 ORDER BY ' + @order
			
print @sql
exec (@sql)
end									
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_crdrtn] TO [public]
GO
