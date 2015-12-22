SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_invhold] @range varchar(8000) = '0=0',
@order varchar(1000) = ' inventory.part_no'

 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = '  SELECT distinct
inventory.location,  
inventory.part_no,   
inventory.description,   
inventory.hold_qty,   
inventory.hold_mfg,  
inventory.hold_ord,   
inventory.hold_rcv,   
inventory.hold_xfr, 
inventory.transit  
 FROM inventory  (nolock), locations l (nolock), region_vw r (nolock)
 WHERE  ' + @range + ' and
   l.location = inventory.location and 
   l.organization_id = r.org_id 
 and ( inventory.hold_qty <> 0 or  
inventory.hold_mfg <> 0 or  
inventory.hold_ord <> 0 or  
inventory.hold_rcv <> 0 or 
inventory.hold_xfr <> 0 or    
inventory.transit <> 0 ) and  
inventory.status <= ''Q''
 ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_invhold] TO [public]
GO
