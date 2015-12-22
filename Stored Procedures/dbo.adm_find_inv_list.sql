SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


Create Procedure [dbo].[adm_find_inv_list] @part_no varchar(30), @org_id varchar(30) = '', @module varchar(10) = '' ,
  @sec_level int = 0 as
begin
DECLARE @xloc varchar(10), @barcoded char(1)

select @barcoded = isnull((select 'Y' from config (nolock) where flag = 'BARCODING' and upper(value_str) like 'Y%'),'N')

create table #t1 (location varchar(10), part_no varchar(30), allocated_amt decimal(20,8), quarantined_amt decimal(20,8), sce_version varchar(10))

if @barcoded = 'Y'
begin
 insert #t1
 exec tdc_get_alloc_qntd_sp '%', @part_no
end

if isnull(@org_id,'') = ''
begin
  SELECT inventory.location,   
         inventory.part_no,   
         inventory.bin_no,   
         inventory.description,   
         inventory.in_stock,   
         inventory.commit_ed,   
	 inventory.hold_qty, 
	 inventory.qty_alloc, 
         inventory.po_on_order,   
	 inventory.hold_mfg, 
	 inventory.hold_ord, 
	 inventory.hold_rcv, 
	 inventory.hold_xfr, 
	 inventory.sch_alloc, 
	 inventory.transit,
         inventory.xfer_commit_ed,
	 #t1.allocated_amt,
	 #t1.quarantined_amt,
	 isnull(left(#t1.sce_version,1),'N'),
         inventory.min_stock,   
         inventory.min_order
    FROM inventory   
    left outer join #t1 on ( inventory.part_no = #t1.part_no ) and
	 ( inventory.location = #t1.location )
   WHERE ( dbo.inventory.part_no = @part_no )   
ORDER BY inventory.part_no ASC,   
         inventory.location ASC,   
         inventory.bin_no ASC   
end
else
begin
  if @module = 'specific'
  begin
  SELECT inventory.location,   
         inventory.part_no,   
         inventory.bin_no,   
         inventory.description,   
         inventory.in_stock,   
         inventory.commit_ed,   
	 inventory.hold_qty, 
	 inventory.qty_alloc, 
         inventory.po_on_order,   
	 inventory.hold_mfg, 
	 inventory.hold_ord, 
	 inventory.hold_rcv, 
	 inventory.hold_xfr, 
	 inventory.sch_alloc, 
	 inventory.transit,
         inventory.xfer_commit_ed,
	 #t1.allocated_amt,
	 #t1.quarantined_amt,
	 isnull(left(#t1.sce_version,1),'N'),
         inventory.min_stock,   
         inventory.min_order
    FROM inventory   
    left outer join #t1 on ( inventory.part_no = #t1.part_no ) and ( inventory.location = #t1.location ) 
   WHERE ( dbo.inventory.part_no = @part_no )
    and inventory.location in
      (select la.location from locations_all la (nolock) where isnull(la.organization_id,'') =  @org_id)
ORDER BY inventory.part_no ASC,   
         inventory.location ASC,   
         inventory.bin_no ASC   
  end
  else
  begin
  SELECT inventory.location,   
         inventory.part_no,   
         inventory.bin_no,   
         inventory.description,   
         inventory.in_stock,   
         inventory.commit_ed,   
	 inventory.hold_qty, 
	 inventory.qty_alloc, 
         inventory.po_on_order,   
	 inventory.hold_mfg, 
	 inventory.hold_ord, 
	 inventory.hold_rcv, 
	 inventory.hold_xfr, 
	 inventory.sch_alloc, 
	 inventory.transit,
         inventory.xfer_commit_ed,
	 #t1.allocated_amt,
	 #t1.quarantined_amt,
	 isnull(left(#t1.sce_version,1),'N'),
         inventory.min_stock,   
         inventory.min_order
    FROM inventory
    left outer join #t1 on ( inventory.part_no = #t1.part_no ) and
	 ( inventory.location = #t1.location )
   WHERE ( dbo.inventory.part_no = @part_no )   
and inventory.location in (select location from dbo.adm_get_related_locs_fn( @module, @org_id, @sec_level))
ORDER BY inventory.part_no ASC,   
         inventory.location ASC,   
         inventory.bin_no ASC   
  end
end
end
GO
GRANT EXECUTE ON  [dbo].[adm_find_inv_list] TO [public]
GO
