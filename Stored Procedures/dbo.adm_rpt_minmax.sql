SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_minmax] @range varchar(8000) = '0=0',
@rstat varchar(255) = ' < "R"',
@order varchar(1000) = ' inventory.part_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @rstat = replace(@rstat,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = 'SELECT distinct
inventory.part_no,  	
inventory.description,  	
inventory.location, 	 
inventory.in_stock, 	 
inventory.po_on_order, 	
inventory.qty_alloc,  	
inventory.min_stock,	 
inventory.min_order,  	
inventory.commit_ed + inventory.sch_alloc,  	
inventory.vendor,  
adm_vend_all.vendor_name,  	
null,  	
inventory.max_stock,  	
inventory.hold_mfg,	 
inventory.hold_ord,	 
inventory.hold_rcv,	 
inventory.hold_xfr,	 
inventory.min_stock - ( inventory.in_stock + inventory.po_on_order - inventory.commit_ed), 
inventory.status, 	
inventory.buyer, 	
inventory.uom	 
FROM inventory (nolock)
left outer join adm_vend_all (nolock) on inventory.vendor = adm_vend_all.vendor_code 
join locations l (nolock) on l.location = inventory.location
join region_vw r (nolock) on l.organization_id = r.org_id
WHERE ( inventory.status <= ''Q'') and  	
 ( ( inventory.min_stock > 0 and ( inventory.in_stock + inventory.po_on_order - inventory.commit_ed) < inventory.min_stock ) or  	
 ( inventory.max_stock > 0 and ( inventory.in_stock + inventory.po_on_order - inventory.commit_ed) > inventory.max_stock ) ) and  
 inventory.status ' + @rstat +	'
 and ( isnull(inventory.void,''N'') = ''N'') and ' + @range +	'
 ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_minmax] TO [public]
GO
