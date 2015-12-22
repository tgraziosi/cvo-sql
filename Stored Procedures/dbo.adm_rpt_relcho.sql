SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_relcho] @range varchar(8000) = '0=0',
@order varchar(1000) = ' orders.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

CREATE TABLE  #rpt_relcho ( 
order_no int,  
order_ext int,  
cust_code varchar(10), 
customer_name varchar(40) NULL,  
total_order_amt float, 
total_order_cost float, 
ship_to_no varchar(10) NULL, 
ship_to_name varchar(40) NULL, 
salesperson varchar(10) NULL, 
who_entered varchar(20) NULL,  
date_entered datetime NULL, 
curr_factor float,  
printed char(1), 
status char(1), 
reason varchar(10) NULL, 
blanket char(1) ,
row_id int identity(1,1))

declare @sql varchar(8000)


select @sql = 'INSERT INTO #rpt_relcho ( order_no, order_ext, cust_code, customer_name, total_order_amt, 
 total_order_cost, ship_to_no, ship_to_name, salesperson, who_entered, date_entered, curr_factor, printed,  
 status, reason, blanket)
SELECT  distinct
 order_no, ext, cust_code, customer_name, 0, 0, ship_to, ship_to_name,  
 salesperson, who_entered, date_entered, curr_factor, printed,  
 status, hold_reason, blanket 										
FROM orders (nolock), adm_cust_all (nolock), locations l (nolock), region_vw r (nolock)
WHERE adm_cust_all.customer_code = orders.cust_code and 
   l.location = orders.location and 
   l.organization_id = r.org_id and
(status = ''B'' or status = ''C'') and  ' + @range + '
ORDER BY ' + @order
			
print @sql
exec (@sql)
									
UPDATE  r
 SET total_order_amt = isnull( 
 (select sum( ordered * price ) 
 FROM ord_list (NOLOCK) 
 WHERE ord_list.order_no =  r.order_no 
 and ord_list.order_ext =  r.order_ext), 0) 								
from #rpt_relcho r												

UPDATE  r 
 SET total_order_cost = isnull( (select sum( ordered * 
 ((std_cost+std_direct_dolrs+std_ovhd_dolrs+std_util_dolrs)* ord_list.conv_factor) ) 
 FROM ord_list (NOLOCK)
 WHERE ord_list.order_no =  r.order_no and ord_list.order_ext =  
      r.order_ext 
 and (ord_list.part_type='M' or ord_list.part_type='J') ), 0 )
from #rpt_relcho r
												
UPDATE r
 SET total_order_cost = isnull( (select sum( ordered * 
 ((inventory.std_cost + inventory.std_direct_dolrs + inventory.std_ovhd_dolrs 
 + inventory.std_util_dolrs) * ord_list.conv_factor) ) 
 FROM ord_list (NOLOCK), inventory (NOLOCK) 
 WHERE ord_list.order_no =  r.order_no and  
 ord_list.order_ext =  r.order_ext and 
 ord_list.part_no = inventory.part_no and 
 ord_list.location = inventory.location and ord_list.part_type <> 'M' 
 and ord_list.part_type <> 'J'), 0 )
from #rpt_relcho r

select order_no, order_ext, cust_code, customer_name, total_order_amt, 
 total_order_cost, ship_to_no, ship_to_name, salesperson, who_entered, date_entered, curr_factor, printed,  
 status, reason, blanket
from #rpt_relcho
order by row_id
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_relcho] TO [public]
GO
