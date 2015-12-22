SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_prodcost] @range varchar(8000) = '0=0',
@order varchar(1000) = ' produce.prod_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = 'SELECT distinct
produce.prod_no,      
produce.prod_date,    	
produce.part_no,   	 
produce.location,    	
produce.qty,   	 
produce.project_key,    	
produce.status,   	 
produce.uom,   	 
produce.tot_prod_avg_cost,    	
produce.tot_prod_direct_dolrs,    	
produce.tot_prod_ovhd_dolrs,    	
produce.tot_prod_util_dolrs,    	
inventory.description,   	 
inventory.avg_cost,   	 
inventory.avg_direct_dolrs,    	
inventory.avg_ovhd_dolrs,    	
inventory.avg_util_dolrs,    	
inventory.std_cost,   	 
inventory.std_direct_dolrs,    	
inventory.std_ovhd_dolrs,    	
inventory.std_util_dolrs,    	
produce.prod_ext,   	 
prod_list_cost.qty,   	 
prod_list_cost.cost  	 
 FROM produce (nolock), inventory (nolock), prod_list_cost (nolock), locations l (nolock), region_vw r (nolock)
 WHERE ( produce.part_no = inventory.part_no ) and   	
      l.location = produce.location and 
      l.organization_id = r.org_id and
( produce.location = inventory.location ) and   	
( produce.prod_no = prod_list_cost.prod_no ) and   	
( produce.prod_ext = prod_list_cost.prod_ext ) and   	
( prod_list_cost.part_no = produce.part_no ) and   	
( dbo.produce.status >= ''R'' AND  ( dbo.produce.status < ''V'' ) ) AND ' + @range + '
 ORDER BY ' + @order
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_prodcost] TO [public]
GO
