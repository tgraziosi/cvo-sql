SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_unpo] @range varchar(8000) = '0=0', @order varchar(1000) = 'releases.po_no'
as
begin
  select @range = replace(@range,'"','''')
  select @order = replace(@order,'"','''')

       CREATE TABLE    #rpt_unpo  (   
      po_no varchar(16),     
      release_date datetime,     
      vendor_no varchar(12),     
      vendor_name varchar(40),   
      location varchar(10) NULL,    
      location_name varchar(40) NULL,   
      part_no varchar(30),    
      description varchar(255) NULL,   
      quantity float,     
      uom char(2) NULL,     
      sched_item_id varchar(20) NULL,   
      operation_qty float NULL,   
      order_qty float NULL,   
      transfer_qty float NULL )

declare @sql varchar(8000)
select @sql = 'SELECT distinct   
   releases.po_no,    
   releases.release_date,
   purchase.vendor_no,     
   (SELECT adm_vend_all.vendor_name FROM adm_vend_all WHERE adm_vend_all.vendor_code = purchase.vendor_no) vendor_name,    
   releases.location,    
  (SELECT locations.name FROM locations  WHERE locations.location = releases.location    
   AND locations.location = sched_location.location AND locations.location = sched_item.location) location_name,   
   releases.part_no,     
   inv_master.description,    
   releases.quantity,      
   inv_master.uom,      
   releases.po_key,    
   isnull((SELECT SUM(sched_operation_item.uom_qty) FROM sched_operation_item    
     WHERE sched_operation_item.sched_item_id = sched_item.sched_item_id),0) operation_qty,   
   isnull((SELECT SUM(sched_order_item.uom_qty) FROM sched_order_item    
     WHERE sched_order_item.sched_item_id = sched_item.sched_item_id),0) order_qty,   
   isnull((SELECT SUM(sched_transfer_item.uom_qty) FROM sched_transfer_item    
     WHERE sched_transfer_item.sched_item_id = sched_item.sched_item_id),0) transfer_qty    
   FROM sched_location (nolock),sched_item (nolock), sched_purchase (nolock), 
   purchase (nolock), releases (nolock), inv_master (nolock), adm_vend_all (nolock),
   locations l (nolock), region_vw r (nolock)
   WHERE sched_item.location = sched_location.location    
   AND sched_item.sched_id = sched_location.sched_id   and
   l.location = releases.location and 
   l.organization_id = r.org_id 
   AND sched_item.source_flag = ''O''
   AND sched_purchase.sched_item_id = sched_item.sched_item_id   
   AND purchase.po_no = sched_purchase.po_no   
   AND releases.location = sched_location.location   
   AND releases.part_no = sched_item.part_no   
   AND releases.row_id = sched_purchase.release_id   
   AND releases.po_no = sched_purchase.po_no   
   AND releases.po_no = purchase.po_no   
   AND releases.po_key = purchase.po_key   
   AND releases.status = ''O''
   AND inv_master.part_no = releases.part_no    
   AND purchase.vendor_no = adm_vend_all.vendor_code    
   AND ' + @range  + '
   order by ' + @order

print @sql
exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_unpo] TO [public]
GO
