SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_produse] @range varchar(8000) = '0=0',
@order varchar(1000) = ' prod_use.prod_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = 'SELECT distinct 
prod_use.location,    	
prod_use.prod_part,     
prod_use.prod_no,       
prod_use.prod_ext,      
prod_use.seq_no,        
prod_use.part_no,       
prod_use.tran_date,     
prod_use.employee_key,          
prod_use.used_qty,      
prod_use.pieces,        
prod_use.scrap_pcs,     
prod_use.shift,         
prod_use.lot_ser,       
prod_use.bin_no,    
prod_use.time_no,    
produce.description,    
inv_master.uom,   
inv_master.description  
FROM prod_use
join produce (nolock) on ( prod_use.prod_no = produce.prod_no ) and 
  ( prod_use.prod_ext = produce.prod_ext )
left outer join inv_master (nolock) on ( prod_use.part_no = inv_master.part_no)
join locations l (nolock) on l.location = prod_use.location 
join region_vw r (nolock) on l.organization_id = r.org_id
WHERE ' + @range  + '
 ORDER BY ' + @order

			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_produse] TO [public]
GO
