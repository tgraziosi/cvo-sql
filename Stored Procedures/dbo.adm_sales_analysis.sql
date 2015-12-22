SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_sales_analysis] @range varchar(8000) = '0=0',
@style int = 0, 
@numrows int = 100, 
@includecm int = 0,
@order varchar(1000) = ''
as

select @range = replace(@range,'tran.tdate',' datediff(day,"01/01/1900",date_shipped) + 693596 ')
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

set rowcount @numrows

select @sql = 'select distinct ' +  
 case @style 
   when 0 then 'adm_cust_all.customer_name '
   when 1 then 'l.location '
   when 2 then 'category '
   when 3 then 'part_no '
   when 4 then 'ship_to_region '
   else 'salesperson '
 end  + '''code'',
 sum(price*(shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ')) / 1000,
 sum(case when shippers.part_type not in (''A'' )
   then (cost + direct_dolrs + ovhd_dolrs + util_dolrs)*
(shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ') else 0 end) / 1000,
 case when sum(price*(shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ')) <> 0
   then ((sum(price*(shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ')) - sum(
case when shippers.part_type not in (''A'')
  then (cost + direct_dolrs + ovhd_dolrs + util_dolrs)*(shipped ' +
 case @includecm when 1 then ' - cr_shipped ' else '' end + ') else 0 end))/sum(price*(shipped ' +
 case @includecm when 1 then ' - cr_shipped ' else '' end + '))) 
   else 0 end
from adm_cust_all (nolock) ,shippers (nolock), locations l (nolock), region_vw r (nolock)
where adm_cust_all.customer_code=shippers.cust_code AND ' + @range + ' and
   l.location = shippers.location and 
   l.organization_id = r.org_id and
 ((price * (shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ') <> 0) 
  or (case when shippers.part_type not in (''A'') then	
    cost * (shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ') else 0 end <> 0))	
group by ' +
 case @style 
   when 0 then ' adm_cust_all.customer_name'
   when 1 then ' l.location'
   when 2 then ' category'
   when 3 then ' part_no'
   when 4 then ' ship_to_region'
   else ' salesperson'
 end + '
order by sum(price*(shipped ' + case @includecm when 1 then ' - cr_shipped ' else '' end + ')) / 1000 Desc'

exec (@sql)
set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[adm_sales_analysis] TO [public]
GO
