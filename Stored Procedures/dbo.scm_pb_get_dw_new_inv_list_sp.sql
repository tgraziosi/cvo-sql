SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[scm_pb_get_dw_new_inv_list_sp] @part_no varchar(30), @location varchar(10) AS
BEGIN		

SELECT l.location,   
         l.part_no,   
         l.bin_no,   
         l.avg_cost,   
         l.in_stock,   
         l.min_stock,   
         l.min_order,   
         l.lead_time,   
         l.labor,   
         l.issued_mtd,   
         l.issued_ytd,   
         l.hold_qty,   
         l.qty_year_end,   
         l.qty_month_end,   
         l.qty_physical,   
         l.entered_who,   
         l.entered_date,   
         l.void,   
         l.void_who,   
         l.void_date,   
         l.std_cost,   
         l.max_stock,   
         l.setup_labor,   
         l.note,   
         l.freight_unit,   
         l.std_labor,   
         l.acct_code,   
         l.std_direct_dolrs,   
         l.std_ovhd_dolrs,   
         l.std_util_dolrs,   
         l.avg_direct_dolrs,   
         l.avg_ovhd_dolrs,   
         l.avg_util_dolrs,   
         l.cycle_date,   
         l.status,   
         l.eoq,   
         l.dock_to_stock,   
         l.order_multiple,   
         isv.in_stock,   
         s.commit_ed,   
         l.hold_qty,   
         s.qty_alloc,   
         r.po_on_order,   
         l.issued_mtd,   
         l.issued_ytd,   
         r.recv_mtd,   
         r.recv_ytd,   
         p.usage_mtd,   
         p.usage_ytd,   
         s.sales_qty_mtd,   
         s.sales_qty_ytd,   
         r.last_recv_date,   
         s.oe_on_order,   
         p.qty_scheduled,   
         p.produced_mtd,   
         p.produced_ytd,   
         s.sales_amt_mtd,   
         s.sales_amt_ytd,   
         p.hold_mfg,   
         s.hold_ord,   
         r.hold_rcv,   
         x.hold_xfr,   
         r.cost,   
         r.last_cost,   
         p.sch_alloc,   
         p.sch_date,   
         0.0 _sort,   
         x.transit,   
         x.commit_ed xfer_commit_ed,
         x.xfer_mtd,   
         x.xfer_ytd,   
         l.hold_qty * 0 _allocated_amt,   
         l.hold_qty * 0 _quarantined_amt,   
         space(1) _barcoded,   
         l.rank_class,   
         l.po_uom,   
         l.so_uom,
			(SELECT MAX(physical.date_entered) FROM physical WHERE (physical.part_no=l.part_no) AND
			 (physical.location = l.location) ) _last_count_date, 
			
			(SELECT DISTINCT purchase.vendor_no   
     			 FROM purchase
                 join pur_list on pur_list.po_no = purchase.po_no AND  
							( ( pur_list.part_no = l.part_no ) AND  
							( pur_list.location like @location ))AND pur_list.void != 'V' and
							( pur_list.qty_received > 0 )
                 where ( purchase.void != 'V' ) AND  
			      (purchase.po_no= (SELECT MAX(pur_list.po_no) FROM pur_list
                 where pur_list.part_no = l.part_no) )) _vendor_code,
			(SELECT isnull((SELECT sum(shipped) 
								   FROM shippers
								  WHERE shippers.date_shipped <= getdate()
									 AND shippers.date_shipped > getdate() - 365
									 AND shippers.part_no = l.part_no
									 AND shippers.location = l.location), 0) / CASE 
isv.in_stock WHEN 0 THEN 1 ELSE isv.in_stock END) as inv_turns,
			isnull(l.qc_qty,0),
		   l.so_qty_increment,
			spd.organization_id
from inv_list l (nolock)
join inv_produce p (nolock) on p.part_no = l.part_no and p.location = l.location
join inv_sales s (nolock) on s.part_no = l.part_no and s.location = l.location
join inv_xfer x (nolock) on x.part_no = l.part_no and x.location = l.location
join inv_recv r (nolock) on r.part_no = l.part_no and r.location = l.location
join inventory_in_stock_vw isv (nolock) on isv.part_no = l.part_no and isv.location = l.location
join adm_locs_with_access_vw spd (nolock) on spd.location = l.location 
   WHERE ( l.part_no = @part_no ) AND  ( l.location like @location )   
ORDER BY l.part_no ASC, l.location ASC 
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_get_dw_new_inv_list_sp] TO [public]
GO
