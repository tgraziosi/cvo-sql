SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[adm_rpt_vendperf] @range varchar(8000) = '0=0', 
  @order varchar(1000) = 'adm_vend_all.vendor_code'
as
begin
  select @range = replace(@range,'"','''')
  select @order = replace(@order,'"','''')

  CREATE TABLE #rpt_vendperf ( 
	vendor_code varchar(12),   
  vendor_name varchar(40),   
  release_date datetime,   
	recv_date datetime,   
  receipt_no integer,   
  po_no varchar(16),   	
  part_no varchar(30),   
  status char(1),   
  rcv_qty float,   
	rtv_qty float,   
  scr_qty float )
		
declare @sql varchar(8000)
select @sql = 'SELECT   distinct
  adm_vend_all.vendor_code ,   		
  adm_vend_all.vendor_name ,   
  rel.due_date ,   		
  receipts.recv_date ,   		
  receipts.receipt_no ,   		
  receipts.po_no ,   		
  receipts.part_no ,   		
  receipts.status ,   		
  receipts.quantity ,    		
  0 ,   
  receipts.rejected   		
   FROM adm_vend_all (nolock), receipts (nolock), locations l (nolock), region_vw r (nolock),
   (select case when releases.confirmed = ''Y'' then confirm_date else due_date end,   
   po_no, po_line, part_no,release_date from releases ) AS   
   rel(due_date, po_no, po_line, part_no, release_date)   
   WHERE ( adm_vend_all.vendor_code = receipts.vendor ) and   	
   l.location = receipts.location and 
   l.organization_id = r.org_id and
   receipts.po_no = rel.po_no and receipts.po_line = rel.po_line and   
   receipts.part_no = rel.part_no and receipts.release_date = rel.release_date and   	
   receipts.quantity > 0 and ' + @range + '
  order by ' + @order

print @sql
exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_vendperf] TO [public]
GO
