SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_item_avail_vw] as
-- tag - 4/17/2012 - rewrite from cvo_ss_item_vw
-- tag - 2/3/2012 - changed available calculation to match tdc_get_alloc_qntd_sp logic
-- tag - 5/2012 - added next po qty and qty in bin 'f01-key' and qty in non-allocatable bins
-- tag - 12/2/2012 - use cvo_in_stock instead of in_stock
-- tag - 4/19/2013 - performance
-- tag - 10/9/2013 - don't need to deduct non-alloc bin allocations any more. It's done in f_get_excluded_bins
-- tag - 08/14/2014  -- add qc qty for drp and matl forecast
-- tag - 02/11/2015 - add plc_status
-- tag - 11/13/2015 - add future order qty
-- select * From cvo_item_avail_vw where location = '001' and future_ord_qty > 0
SELECT         
 isnull(t1.category,'') as Brand,
 isnull(t1.type_code,'') as ResType,
 isnull(t8.category_3,'') as PartType, -- 061713 - add pre TB request
 isnull(t8.field_2,'') as Style,
 t1.part_no,         
 t1.description,        
 t3.location,         
 --t3.in_stock,
 cast(t3.cvo_in_stock as int) in_stock, 
 -- remove for SA - no longer needed - tag 032713
 --Qty_on_so = isnull( (SELECT SUM(ordered-shipped) from ord_list ol (nolock)
	--inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
	--where ol.part_no = t3.part_no and ol.status < 'R' and o.type='I'), 0),
 --qty_commit = t3.commit_ed ,    
 -- sch_alloc,
 -- tag  - for SA - 032213
 
 --SOF = isnull((SELECT dbo.f_cvo_get_soft_alloc_stock (0, t3.location, t3.part_no)), 0),
 SOF = isnull(sof.sof_qty,0),
 
 -- isnull((select sum(quantity) from cvo_soft_alloc_det (nolock) where location=t3.location and part_no=t3.part_no and 
 --  status in (0,1)) , 0),
	
 Allocated = ISNULL((select SUM(qty) from tdc_soft_alloc_tbl (nolock) 
 where part_no=t1.part_no
 and location=t3.location 
 -- dont need anymore - 10/09/2013 - AND bin_no NOT IN (SELECT bin_no FROM dbo.cvo_lot_bin_stock_exclusions (nolock) WHERE location = t3.location) -- v1.3
 and (order_no <>0 OR (order_no = 0 and dest_bin = 'CUSTOM'))),0),
   
 Quarantine = 	ISNULL((SELECT sum(qty) -- quarantine 
	    FROM lot_bin_stock (nolock)
	   WHERE location = t3.location
	     AND part_no = t1.part_no
	     AND bin_no in (SELECT bin_no 
    	      FROM tdc_bin_master (nolock)
    	     WHERE usage_type_code = 'QUARANTINE' 
		AND location = t3.location)), 0) ,
 
 Non_alloc = isnull( z1.qty, 0),
 
 Replen_Qty_Not_SA = 
	case when isnull(t3.replen_qty,0) >= isnull(sof.sof_qty,0) 
	then t3.replen_qty - isnull(sof.sof_qty, 0)
	else 0 end,
	
 qty_avl = t3.cvo_in_stock 
	-
	isnull((select sum(qty)
	from tdc_soft_alloc_tbl (nolock)
	where location = t3.location
	and part_no = t1.part_no
	-- dont need anymore - 10/09/2013 - AND bin_no NOT IN (SELECT bin_no FROM dbo.cvo_lot_bin_stock_exclusions (nolock) WHERE location = t3.location) -- v1.3
	and (order_no <> 0 OR (order_no = 0 and dest_bin = 'CUSTOM'))),0) 
	-
	ISNULL((SELECT sum(qty) -- quarantine 
	    FROM lot_bin_stock (nolock)
	   WHERE location = t3.location
	     AND part_no = t1.part_no
	     AND bin_no in (SELECT bin_no 
    	      FROM tdc_bin_master (nolock)
    	     WHERE usage_type_code = 'QUARANTINE' 
		AND location = t3.location)), 0) 
	-
	--t3.replen_qty -- tag 092613 - use replen qty not SA
    case when isnull(t3.replen_qty,0) >= isnull(sof.sof_qty,0) 
	then t3.replen_qty - isnull(sof.sof_qty, 0)
	else 0 end
	- 
--	isnull((SELECT dbo.f_cvo_get_soft_alloc_stock (0, t3.location, t3.part_no)), 0)
	isnull(sof.sof_qty,0)
	-
	isnull(z1.qty,0) 
 ,   
 
 qty_hold = hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr,   

 t3.replen_qty  as ReplenQty,
 
 Qty_Key = isnull((select sum(qty) 
	from lot_bin_stock (nolock) 
	where location = t3.location
	and part_no = t1.part_no
	and bin_no ='F01-Key'), 0),
 
 tot_cost_ea = case when t3.inv_cost_method = 'S' then t3.std_cost + t3.std_direct_dolrs + t3.std_ovhd_dolrs + t3.std_util_dolrs        else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end,        
 
 tot_ext_cost = (case when t3.inv_cost_method = 'S' then t3.std_cost + t3.std_direct_dolrs + t3.std_ovhd_dolrs + t3.std_util_dolrs        
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end)        
--   * (in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),        
   * (cvo_in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),        

 po_on_order,

 --(select sum(quantity-received) from releases (nolock) where part_no = t3.part_no and location = t3.location
 -- and quantity>received and status='O' 
 -- and confirm_date = (select min (confirm_date) from releases (nolock) where part_no = t3.part_no
	--and location = t3.location and quantity>received and status='O') ) as NextPOOnOrder,

 --(select min (confirm_date) from releases (nolock) where part_no = t3.part_no
	--and location = t3.location and quantity>received and status='O') as NextPODueDate,
	
 (select sum(quantity-received) from releases (nolock) where part_no = t1.part_no and location = t3.location
  and quantity>received and status='O' 
  and isnull(inhouse_date,confirm_date) = (select min (isnull(inhouse_date,confirm_date)) from releases (nolock) where part_no = t1.part_no
	and location = t3.location and quantity>received and status='O') ) as NextPOOnOrder,

 (select min(isnull(inhouse_date,confirm_date)) from releases (nolock) where part_no = t1.part_no
	and location = t3.location and quantity>received and status='O') as NextPODueDate,
	      
 t3.lead_time,        
 t3.min_order,        
 t3.min_stock,        
 t3.max_stock,        
 t3.order_multiple,
 t8.field_26 ReleaseDate,
 t8.field_28 POM_date,
 isnull(t8.category_1,'N') Watch,
 plc_status = case when (t8.field_28 is null or t8.field_28 > getdate()) and 'N' = isnull(t8.category_1,'N') 
		   then 'Current' else 'Disc' end,
 t8.category_2 Gender,
 t8.field_10 Material,
 t1.vendor,
 isnull(t8.field_3,'') as Color_desc, -- added 071812
 
  ReserveQty = 	ISNULL((SELECT sum(qty) as Reserve_qty
from lot_bin_stock (nolock) where location = t3.location AND part_no = t1.part_no AND bin_no like 'rr0%'),0),

-- 081414  -- add qc qty for drp and matl forecast
QcQty = isnull((select sum(qty) as QcQty from lot_bin_recv lbr (nolock) where lbr.qc_flag = 'y' and 
lbr.location = t3.location and lbr.part_no = t1.part_no),0)

, future_ord_qty = fo.future_open_qty

-- select top 10 * from lot_bin_recv
        
FROM inv_master t1 (nolock) 
inner join inv_master_add t8 (nolock) on t1.part_no = t8.part_no
-- inner join inventory t3 (nolock) on t1.part_no = t3.part_no
inner join cvo_inventory2 t3 (nolock) on t1.part_no = t3.part_no
-- left join dbo.f_get_excluded_bins(1) z1 on t1.part_no = z1.part_no and t3.location = z1.location
left join dbo.f_get_excluded_bins_1_vw z1 on t1.part_no = z1.part_no and t3.location = z1.location
left join 
(select sof.part_no, sof.location, sum(sa_stock) as sof_qty from cvo_get_soft_alloc_stock_vw sof (nolock) group by sof.part_no, sof.location) sof
on t1.part_no = sof.part_no and t3.location = sof.location
LEFT OUTER JOIN
-- future orders
(SELECT  ol.part_no , ol.location,
        future_open_qty = SUM(ol.ordered - ol.shipped - ISNULL(ha.qty, 0))
		FROM    orders o ( NOLOCK )
        INNER JOIN ord_list ol ( NOLOCK ) ON ol.order_no = o.order_no
                                             AND ol.order_ext = o.ext
        LEFT OUTER JOIN dbo.cvo_hard_allocated_vw ha ( NOLOCK ) ON ha.line_no = ol.line_no
                                                              AND ha.order_ext = ol.order_ext
                                                              AND ha.order_no = ol.order_no
        LEFT OUTER JOIN cvo_soft_alloc_det sa ( NOLOCK ) ON sa.order_no = ol.order_no
                                                            AND sa.order_ext = ol.order_ext
                                                            AND sa.line_no = ol.line_no
                                                            AND sa.part_no = ol.part_no
WHERE   o.status < 'r'
		AND o.status <> 'c'  -- 07/29/2015 - dont include credit hold orders
        AND o.type = 'i'
        AND ol.ordered > ol.shipped + ISNULL(ha.qty, 0)
        AND ISNULL(sa.status, -3) = -3 -- future orders not yet soft allocated
        AND ol.part_type = 'P'
GROUP BY ol.part_no, ol.location) fo 
	ON fo.part_no = t3.part_no AND fo.location = t3.location
where  t3.void<>'V'
-- and T3.LOCATION = '001'











GO
GRANT REFERENCES ON  [dbo].[cvo_item_avail_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_item_avail_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_item_avail_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_item_avail_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_item_avail_vw] TO [public]
GO
