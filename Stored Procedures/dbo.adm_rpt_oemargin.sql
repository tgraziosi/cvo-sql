SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_oemargin] @range varchar(8000) = '0=0',
@ordstat varchar(1000) = '',
@ordstatus varchar(1000) = '',
@margpct int = 0,
@order varchar(1000) = ' orders.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @ordstat = replace(@ordstat,'"','''')
select @ordstatus = replace(@ordstatus,'"','''')
select @order = replace(@order,'"','''')

CREATE TABLE  #rpt_oemargin ( 
cust_code varchar(12), 
customer_name varchar(40) NULL, 
order_no int, 
order_ext int, 
part_no varchar(32), 
location varchar(12), 
description varchar(255) NULL, 
uom char(2), 
shipped float, 
price_type char(1) NULL, 
price float, 
cost float, 
salesperson varchar(16) NULL, 
date_shipped datetime, 
who_entered varchar(30) NULL, 
status char(1), 
margin float ,
conv_factor decimal(20,8))

create index m1 on #rpt_oemargin (cust_code, date_shipped, order_no, order_ext, part_no)
create index m2 on #rpt_oemargin (part_no,location)

declare @sql varchar(8000)

select @sql = '
INSERT INTO  #rpt_oemargin (cust_code, customer_name, order_no, order_ext, part_no, location,
description, uom, shipped, price_type, price, cost, salesperson, date_shipped, who_entered, status,
margin, conv_factor)
SELECT distinct
orders.cust_code,  
adm_cust_all.customer_name,  
orders.order_no,  
orders.ext,  
ord_list.part_no, 		
ord_list.location, 
ord_list.description,  
ord_list.uom,  
ord_list.ordered,  
ord_list.price_type,  
ord_list.price,  	
(ord_list.cost+ord_list.direct_dolrs+ord_list.ovhd_dolrs+ord_list.util_dolrs),  
orders.salesperson,  
orders.sch_ship_date,  
orders.who_entered,  
orders.status,  
0 ,
ord_list.conv_factor
FROM orders (nolock), ord_list (nolock), adm_cust_all (nolock), locations l (nolock), region_vw r (nolock)
WHERE orders.order_no = ord_list.order_no  and
   l.location = ord_list.location and 
   l.organization_id = r.org_id
AND orders.ext = ord_list.order_ext  
AND orders.cust_code = adm_cust_all.customer_code  
AND ' + @ordstat + ' orders.type = ''I'' and ' + @range + '
 ORDER BY ' + @order

exec (@sql)
       
UPDATE  #rpt_oemargin 	
 SET cost=(inventory.avg_cost+inventory.avg_direct_dolrs+inventory.avg_ovhd_dolrs+inventory.avg_util_dolrs) 	
 FROM inventory 	
 WHERE  #rpt_oemargin.part_no=inventory.part_no AND 
        #rpt_oemargin.location=inventory.location and inventory.inv_cost_method <> 'S'

UPDATE  #rpt_oemargin 
 SET cost=(inventory.std_cost+inventory.std_direct_dolrs+inventory.std_ovhd_dolrs+inventory.std_util_dolrs) 	
 FROM inventory 	
 WHERE  #rpt_oemargin.part_no=inventory.part_no AND 
        #rpt_oemargin.location=inventory.location and inventory.inv_cost_method = 'S'
        
select @order = replace(@order,'sch_ship_date','date_shipped')

select @sql = '
INSERT INTO  #rpt_oemargin (cust_code, customer_name, order_no, order_ext, part_no, location,
description, uom, shipped, price_type, price, cost, salesperson, date_shipped, who_entered, status,
margin, conv_factor)
 SELECT distinct  
orders.cust_code,  
adm_cust_all.customer_name,  
orders.order_no,  
orders.ext,  
ord_list.part_no, 		
ord_list.location, 
ord_list.description,  
ord_list.uom,  
ord_list.shipped,  
ord_list.price_type,  
ord_list.price,  	
(ord_list.cost+ord_list.direct_dolrs+ord_list.ovhd_dolrs+ord_list.util_dolrs),  
orders.salesperson,  
orders.date_shipped,  
orders.who_entered,  
orders.status,  
0 ,
ord_list.conv_factor
FROM orders (nolock), ord_list (nolock), adm_cust_all (nolock), locations l (nolock), region_vw r (nolock)
WHERE orders.order_no = ord_list.order_no  and
   l.location = ord_list.location and 
   l.organization_id = r.org_id
AND orders.ext = ord_list.order_ext  
AND orders.cust_code = adm_cust_all.customer_code  
AND ' + @ordstatus + ' orders.type = ''I'' and ' + @range + '
ORDER BY ' + @order

exec (@sql)

UPDATE  #rpt_oemargin 
SET margin = case when price <> 0 then ( ( price - (cost * conv_factor) ) / price ) else 0 end,
cost = cost * conv_factor
       
DELETE FROM  #rpt_oemargin
WHERE margin * 100 >  @margpct	
	
select cust_code, customer_name, order_no, order_ext, part_no, location,
description, uom, shipped, price_type, price, cost, salesperson, date_shipped, who_entered, status,
margin
from #rpt_oemargin
order by cust_code, date_shipped, order_no, order_ext, part_no

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_oemargin] TO [public]
GO
