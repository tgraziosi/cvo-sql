SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_qcrpt] @range varchar(8000) = '0=0',
@grouped varchar(255) = ' NULL,NULL',
@status varchar(255) = ' and ( 0=0 )',
@sourcetype varchar(255) = ' and ( 0=0 )',
@order varchar(1000) = ' qc_results.location'

 as


BEGIN
select @range = replace(@range,'"','''')
select @grouped = replace(@grouped,'"','''')
select @status = replace(@status,'"','''')
select @sourcetype = replace(@sourcetype,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = ' SELECT distinct
qc_results.location,    
qc_results.part_no,    
inventory.description,    
qc_results.qc_no,    
qc_results.tran_code,    
qc_results.tran_no,    
inventory.uom,    
qc_results.lot_ser,    
qc_results.bin_no,    
qc_results.status,    
qc_results.qc_qty,    
qc_results.reject_qty,    
qc_results.reject_type,    
qc_results.inspector,    
qc_results.who_inspected,    
qc_results.date_inspected,    
qc_results.who_entered,    
qc_results.date_entered,    
qc_results.date_complete,    
qc_results.reason, ' +
@grouped + '
FROM inventory (nolock), qc_results (nolock) , locations l (nolock), region_vw r (nolock)
WHERE ' + @range + ' and
   l.location = inventory.location and 
   l.organization_id = r.org_id 
and  ( inventory.part_no = qc_results.part_no ) 
and  ( inventory.location = qc_results.location ) ' +
@status +  @sourcetype + ' 
ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_qcrpt] TO [public]
GO
