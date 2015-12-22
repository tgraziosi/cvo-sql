SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_recvng] @range varchar(8000) = '0=0',
@grouping varchar(255) = ' NULL,NULL,NULL',
@overtol varchar(255) = '',
@rstatus varchar(255) = ' receipts.status = "R"',
@order varchar(1000) = ' receipts.receipt_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @grouping = replace(@grouping,'"','''')
select @overtol = replace(@overtol,'"','''')
select @rstatus = replace(@rstatus,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = ' SELECT distinct
receipts.receipt_no,    	
receipts.vendor,    	
receipts.po_no,    	
receipts.recv_date,    	
receipts.part_type,    	
receipts.part_no,    	
receipts.quantity,    	
receipts.unit_cost,    	
receipts.location,    	
receipts.unit_measure,    	
receipts.ext_cost, 
receipts.status,    			 
pur_list.description,    	
adm_vend_all.vendor_name,    	
inv_master.description,    	
receipts.over_flag,    
receipts.nat_curr,    
receipts.curr_factor,   
receipts.curr_cost,    	
receipts.who_entered, 	
glcurr_vw.symbol, ' + @grouping + '
 FROM receipts (nolock)
 join adm_vend_all (nolock) on ( receipts.vendor = adm_vend_all.vendor_code )
 left outer join pur_list (nolock) on ( receipts.po_no = pur_list.po_no) and  	
   ( receipts.part_no = pur_list.part_no) and ( receipts.po_line = pur_list.line )
 left outer join inv_master (nolock) on  ( receipts.part_no = inv_master.part_no)   	
 join glcurr_vw (nolock) on  ( receipts.nat_curr = glcurr_vw.currency_code) 
 join locations l (nolock) on    l.location = receipts.location 
 join region_vw r (nolock) on    l.organization_id = r.org_id 
 WHERE ' + @rstatus + '
 and ' + @range + @overtol + '	
ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_recvng] TO [public]
GO
