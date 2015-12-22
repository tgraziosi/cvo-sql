SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_prodvar] @range varchar(8000) = '0=0',
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
prod_list.description,  
IsNull(inv_list.std_cost,0.0),   
prod_list.prod_no,   
produce.prod_date,   
produce.part_no,   
produce.location,   
produce.qty,   
produce.status,   
produce.uom,   
produce.conv_factor,   
produce.prod_ext,   
IsNull(inv_list.std_cost+inv_list.std_direct_dolrs+inv_list.std_ovhd_dolrs+inv_list.std_util_dolrs,0.0),   
IsNull(produce.description, IsNull(inv_master.description,''''))    ''produce_description'', 
IsNull((SELECT SUM(prod_list_cost.cost * prod_list_cost.qty)         FROM prod_list_cost WHERE prod_list.prod_no = prod_list_cost.prod_no and prod_list.prod_ext = .prod_list_cost.prod_ext and .prod_list.line_no = .prod_list_cost.line_no),0.0) , 
IsNull((SELECT SUM(prod_list_cost.direct_dolrs * prod_list_cost.qty) FROM prod_list_cost WHERE prod_list.prod_no = prod_list_cost.prod_no and prod_list.prod_ext = .prod_list_cost.prod_ext and .prod_list.line_no = .prod_list_cost.line_no),0.0) ,  
IsNull((SELECT SUM(prod_list_cost.ovhd_dolrs * prod_list_cost.qty)   FROM prod_list_cost WHERE prod_list.prod_no = prod_list_cost.prod_no and prod_list.prod_ext = .prod_list_cost.prod_ext and .prod_list.line_no = .prod_list_cost.line_no),0.0) ,   
IsNull((SELECT SUM(prod_list_cost.util_dolrs * prod_list_cost.qty)   FROM prod_list_cost WHERE prod_list.prod_no = prod_list_cost.prod_no and prod_list.prod_ext = .prod_list_cost.prod_ext and .prod_list.line_no = .prod_list_cost.line_no),0.0) ,   
IsNull(inv_list.std_direct_dolrs,0.0) ,   
IsNull(inv_list.std_ovhd_dolrs,0.0) ,   
IsNull(inv_list.std_util_dolrs,0.0),   
IsNull((SELECT SUM(prod_list_cost.qty)   FROM prod_list_cost WHERE prod_list.prod_no = prod_list_cost.prod_no and prod_list.prod_ext = .prod_list_cost.prod_ext and .prod_list.line_no = .prod_list_cost.line_no),0.0) ''pl_qty''   
FROM prod_list
left outer join inv_list (nolock) on prod_list.part_no = inv_list.part_no and
  prod_list.location = inv_list.location 
join produce (nolock) on prod_list.prod_no = produce.prod_no AND 
  prod_list.prod_ext = produce.prod_ext 
left outer join inv_master (nolock) on produce.part_no = inv_master.part_no 
join locations l (nolock) on l.location = prod_list.location 
join region_vw r (nolock) on l.organization_id = r.org_id 
WHERE prod_list.direction < 0 AND  prod_list.constrain <> ''Y'' and  
prod_list.constrain <> ''C'' and ' + @range + '
 ORDER BY ' + @order
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_prodvar] TO [public]
GO
