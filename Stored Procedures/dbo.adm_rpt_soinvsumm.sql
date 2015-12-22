SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_soinvsumm] @range varchar(8000) = '0=0',
@group2 varchar(1000) = 'NULL,',
@precision int = 2,
@order varchar(1000) = ' orders.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @group2 = replace(@group2,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = '
SELECT distinct orders.order_no,  
orders.date_entered,    
orders.date_shipped,   
orders.invoice_no,    
orders.invoice_date,    
orders.total_invoice,  
orders.total_amt_order,   
orders.status,   
orders.printed,   
orders.type,    
orders.back_ord_flag,   
orders.discount,   
orders.changed,  
orders.freight,    
orders.freight_allow_pct,   
orders.freight_allow_type,   
orders.ext,   
orders.cust_code,  
orders.ship_to,  
adm_cust_all.customer_name,  
orders.ship_to_name,    
orders.curr_key,
' + @group2 + '
orders.curr_key,    
nat.symbol + ''~!@'' + home.symbol,    
orders.curr_factor , ' + convert(varchar,@precision) + '
FROM orders (nolock)
join adm_cust_all (nolock) on (orders.cust_code = adm_cust_all.customer_code)
join glco gl (nolock) on 1=1
left outer join glcurr_vw nat (nolock) on (orders.curr_key = nat.currency_code) 
join glcurr_vw home (nolock) on (gl.home_currency = home.currency_code) 
join locations l (nolock) on    l.location = orders.location 
join region_vw r (nolock) on    l.organization_id = r.org_id
WHERE ' + @range + ' and (orders.status = ''S'' or orders.status = ''T'')  
ORDER BY ' +  @order
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_soinvsumm] TO [public]
GO
