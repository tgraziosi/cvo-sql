SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 27/07/2012 - exclude soft allocated quantity from available
-- v1.1 CT			  - Add replen qty
-- v1.2 CB 10/04/2013 - Issue #1204 - Display fields as per inventory screen  
 
CREATE PROCEDURE [dbo].[adm_ord_inv_list] @part_no varchar(30), @loc varchar(10)  
AS  
BEGIN    
DECLARE @xloc varchar(10), @barcoded char(1), @sf_alloc_qty decimal(20,8)  
  
select @barcoded = isnull((select 'Y' from config (nolock) where flag = 'BARCODING' and upper(value_str) like 'Y%'),'N')  
  
create table #t1 (location varchar(10), part_no varchar(30), allocated_amt decimal(20,8), quarantined_amt decimal(20,8), sce_version varchar(10))  
create table #t2 (soft_allocated_amt decimal(20,8))  
  
if @barcoded = 'Y'  
begin  
  insert #t1  
  exec tdc_get_alloc_qntd_sp @loc, @part_no  
end  
  
-- v1.0 Start
insert	#t2
EXEC dbo.cvo_get_available_stock_sp 0, @loc, @part_no
SELECT	@sf_alloc_qty = soft_allocated_amt
FROM	#t2
-- v1.0 end

SELECT inventory.location,     
         inventory.part_no,     
         inventory.note,     
         inventory.in_stock,     
         inventory.commit_ed,     
         inventory.hold_qty,     
         inventory.qty_alloc,     
         inventory.po_on_order,     
         inventory.hold_mfg,     
         inventory.hold_ord,     
         inventory.hold_rcv,     
         inventory.hold_xfr,     
         @sf_alloc_qty sch_alloc,     
         inventory.transit,  
   inventory.xfer_commit_ed,  
         #t1.allocated_amt,  
         #t1.quarantined_amt,  
  0,  
  isnull(left(#t1.sce_version,1),'N') ,
	inventory.cvo_in_stock,   -- v1.0 
	inventory.replen_qty,	-- v1.1 - return qty on replenishment
    inventory.cvo_in_stock - inventory.in_stock c_non_alloc_bin_qty, -- v1.2 qty in non allocatable bins
	0 as c_repl_qty_sa -- v1.2
    FROM inventory (nolock)  
    left outer join #t1 (nolock) on ( inventory.part_no = #t1.part_no ) and  
         ( inventory.location = #t1.location )    
   WHERE ( inventory.part_no = @part_no ) AND    
         ( inventory.location like @loc )     
ORDER BY inventory.part_no ASC,     
         inventory.location ASC     
  
END  
GO
GRANT EXECUTE ON  [dbo].[adm_ord_inv_list] TO [public]
GO
