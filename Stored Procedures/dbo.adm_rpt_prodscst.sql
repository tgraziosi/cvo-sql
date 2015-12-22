SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_prodscst] @range varchar(8000) = '0=0',
@order varchar(1000) = ' prod_list.prod_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = 'SELECT distinct
prod_list.part_no,    	
prod_list.uom,    	
prod_list.plan_qty,    	
prod_list.used_qty,    	
prod_list.conv_factor,    	
inventory.description,    	
inventory.std_cost,    	
prod_list.prod_no,    	
produce.prod_date,    	
produce.part_no,    	
produce.location,    	
produce.qty,    	
produce.status,    	
produce.uom,    	
produce.conv_factor,    	
inventory.type_code,    	
prod_list.prod_ext,    	
inventory.status,    	
produce.description,    	
inventory.std_cost+inventory.std_direct_dolrs+inventory.std_ovhd_dolrs+inventory.std_util_dolrs _std_cost 	
 FROM prod_list (nolock), inventory (nolock), produce (nolock), locations l (nolock), region_vw r (nolock)
WHERE ( prod_list.part_no = inventory.part_no ) and   	
      l.location = prod_list.location and 
      l.organization_id = r.org_id and
( prod_list.location = inventory.location ) and   	
( prod_list.prod_no = produce.prod_no ) and   	
( prod_list.prod_ext = produce.prod_ext ) and 
( dbo.prod_list.direction < 0 ) and   	
( dbo.prod_list.constrain <> ''Y'' ) and   	
( dbo.prod_list.constrain <> ''C'' ) and ' + @range + '
 ORDER BY ' + @order
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_prodscst] TO [public]
GO
