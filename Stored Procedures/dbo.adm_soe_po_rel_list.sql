SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
-- v1.1 CT 21/05/2013 - Issue #1278 - Change releases.confirm_date to releases.inhouse_date  
CREATE PROCEDURE [dbo].[adm_soe_po_rel_list] @order_no int, @order_ext int, @line_no int,  
  @qty decimal(20,8), @part_no varchar(30), @location varchar(10) as  
BEGIN  
  
	SELECT 
		@order_no, 
		@order_ext, 
		@line_no, 
		@qty, 
		@part_no, 
		@location,  
		releases.po_no,      
		releases.part_no,     
		releases.location,     
		releases.part_type,     
		releases.release_date,     
		releases.quantity,     
		case when releases.status = 'C' then releases.quantity else releases.received end,     
		releases.status,  
		-- START v1.1
		releases.inhouse_date confirm_date,
        --releases.confirm_date,     
		-- END v1.1
		releases.confirmed,     
		releases.lb_tracking,     
		releases.conv_factor,     
		releases.prev_qty,     
		releases.po_key,     
		adm_vend_all.vendor_code,     
		adm_vend_all.vendor_name,     
		pur_list.line,     
		purchase.status  ,  
		orders_auto_po.order_no,  
		orders_auto_po.line_no,  
		case when orders_auto_po.order_no = @order_no and orders_auto_po.line_no = @line_no  
		and orders_auto_po.part_no = @part_no and orders_auto_po.location = @location  
		then 2   
		when orders_auto_po.order_no is not null then 1 else 0 end oap_ind  
    FROM releases     
    join purchase_all purchase (nolock) on ( releases.po_no = purchase.po_no )  
    join adm_vend_all (nolock) on ( purchase.vendor_no = adm_vend_all.vendor_code )  
    join pur_list (nolock) on ( releases.po_no = pur_list.po_no ) and    
         ( releases.part_no = pur_list.part_no ) and    
         ( releases.po_line = pur_list.line )   
    left outer join orders_auto_po (nolock) on releases.po_no = orders_auto_po.po_no and   
 releases.ord_line = orders_auto_po.line_no and releases.part_no = orders_auto_po.part_no and  
 releases.location = orders_auto_po.location  
   WHERE ( dbo.releases.part_no like @part_no ) AND   
         ( dbo.releases.location like @location ) AND    
         ( (dbo.releases.status <> 'C' )  or   
          (isnull(orders_auto_po.order_no,-1) = @order_no and isnull(orders_auto_po.line_no,-1) = @line_no) )  
ORDER BY oap_ind desc, orders_auto_po.order_no,releases.status DESC,     
         releases.release_date ASC     
end  
GO
GRANT EXECUTE ON  [dbo].[adm_soe_po_rel_list] TO [public]
GO
