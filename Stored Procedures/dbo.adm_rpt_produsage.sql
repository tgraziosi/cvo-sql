SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_produsage] @range varchar(8000) = '0=0',
@grouped varchar(1000) = 'NULL',
@order varchar(1000) = ' prod_use.prod_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @grouped = replace(@grouped,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = 'SELECT distinct
prod_use.prod_no,  
prod_use.prod_ext,   
prod_use.prod_part,  
prod_use.time_no,    
prod_use.employee_key,  
prod_use.location,   
prod_use.seq_no,    
prod_use.part_no,    
prod_use.tran_date,    
prod_use.used_qty,    
prod_use.pieces, 
prod_use.shift,     
prod_use.scrap_pcs,    
prod_use.lot_ser,    
prod_use.bin_no,    
produce.description,  
inv_master.description,    
inv_master.uom, ' +  @grouped + '
FROM prod_use
join produce (nolock) on ( prod_use.prod_no = produce.prod_no ) and  
  ( prod_use.prod_ext = produce.prod_ext )
left outer join inv_master (nolock) on ( prod_use.part_no = inv_master.part_no) 
join locations l (nolock) on l.location = prod_use.location 
join region_vw r (nolock) on l.organization_id = r.org_id
WHERE ' + @range + '
 ORDER BY ' + @order + ', prod_use.prod_ext , 
prod_use.seq_no ,prod_use.tran_date'
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_produsage] TO [public]
GO
