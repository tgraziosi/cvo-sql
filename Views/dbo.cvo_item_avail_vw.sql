SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[cvo_item_avail_vw] AS
-- tag - 4/17/2012 - rewrite from cvo_ss_item_vw
-- tag - 2/3/2012 - changed available calculation to match tdc_get_alloc_qntd_sp logic
-- tag - 5/2012 - added next po qty and qty in bin 'f01-key' and qty in non-allocatable bins
-- tag - 12/2/2012 - use cvo_in_stock instead of in_stock
-- tag - 4/19/2013 - performance
-- tag - 10/9/2013 - don't need to deduct non-alloc bin allocations any more. It's done in f_get_excluded_bins
-- tag - 08/14/2014  -- add qc qty for drp and matl forecast
-- tag - 02/11/2015 - add plc_status
-- tag - 11/13/2015 - add future order qty
-- tag = 2/8/16 - add drp usage figures
-- tag - 8/25/2016 - for IFP, get the QC Hold qty from inv_recv, not lot_bin_stock

/*
 select top 10 * From cvo_item_avail_vw where location = '001' and future_ord_qty > 0 and backorder <> 0
 select top 10 * From cvo_item_avail_r2_vw where location = '001' and future_ord_qty > 0 and backorder <> 0 
*/

SELECT         
 ISNULL(i.category,'') AS Brand,
 ISNULL(i.type_code,'') AS ResType,
 ISNULL(ia.category_3,'') AS PartType, -- 061713 - add pre TB request
 ISNULL(ia.field_2,'') AS Style,
 i.part_no,         
 i.description,        
 inv.location,         
 --t3.in_stock,
 CAST(inv.cvo_in_stock AS INT) in_stock, 
 -- remove for SA - no longer needed - tag 032713
 --Qty_on_so = isnull( (SELECT SUM(ordered-shipped) from ord_list ol (nolock)
	--inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
	--where ol.part_no = t3.part_no and ol.status < 'R' and o.type='I'), 0),
 --qty_commit = t3.commit_ed ,    
 -- sch_alloc,
 -- tag  - for SA - 032213
 
 --SOF = isnull((SELECT dbo.f_cvo_get_soft_alloc_stock (0, t3.location, t3.part_no)), 0),
 SOF = ISNULL(sof.sof_qty,0),
 
 -- isnull((select sum(quantity) from cvo_soft_alloc_det (nolock) where location=t3.location and part_no=t3.part_no and 
 --  status in (0,1)) , 0),
	
 Allocated = ISNULL(alloc.alloc,0),
   
 Quarantine = ISNULL(q.q_qty, 0)  ,
 
 Non_alloc = ISNULL( z1.qty, 0),
 
 Replen_Qty_Not_SA = 
	CASE WHEN ISNULL(inv.replen_qty,0) >= ISNULL(sof.sof_qty,0) 
	THEN inv.replen_qty - ISNULL(sof.sof_qty, 0)
	ELSE 0 END,
	
 qty_avl = inv.cvo_in_stock 
	-
	ISNULL(alloc.alloc,0)
	-
	ISNULL(q.q_qty, 0) 
	-
	--t3.replen_qty -- tag 092613 - use replen qty not SA
    CASE WHEN ISNULL(inv.replen_qty,0) >= ISNULL(sof.sof_qty,0) 
	THEN inv.replen_qty - ISNULL(sof.sof_qty, 0)
	ELSE 0 END
	- 
--	isnull((SELECT dbo.f_cvo_get_soft_alloc_stock (0, t3.location, t3.part_no)), 0)
	ISNULL(sof.sof_qty,0)
	-
	ISNULL(z1.qty,0) 
 ,   
 
 qty_hold = hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr,   

 inv.replen_qty  AS ReplenQty,
 
 Qty_Key = ISNULL((SELECT SUM(qty) 
	FROM lot_bin_stock (NOLOCK) 
	WHERE location = inv.location
	AND part_no = i.part_no
	AND bin_no ='F01-Key'), 0),
 
 tot_cost_ea = CASE WHEN inv.inv_cost_method = 'S' THEN inv.std_cost + inv.std_direct_dolrs + inv.std_ovhd_dolrs + inv.std_util_dolrs        ELSE avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs END,        
 
 tot_ext_cost = (CASE WHEN inv.inv_cost_method = 'S' THEN inv.std_cost + inv.std_direct_dolrs + inv.std_ovhd_dolrs + inv.std_util_dolrs        
    ELSE avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs END)        
--   * (in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),        
   * (cvo_in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),        

 po_on_order,


 (SELECT SUM(quantity-received) FROM releases (NOLOCK) WHERE part_no = i.part_no AND location = inv.location
  AND quantity>received AND status='O' 
  AND ISNULL(inhouse_date,confirm_date) = (SELECT MIN (ISNULL(inhouse_date,confirm_date)) FROM releases (NOLOCK) WHERE part_no = i.part_no
	AND location = inv.location AND quantity>received AND status='O') ) AS NextPOOnOrder,

 (SELECT MIN(ISNULL(inhouse_date,confirm_date)) FROM releases (NOLOCK) WHERE part_no = i.part_no
	AND location = inv.location AND quantity>received AND status='O') AS NextPODueDate,
	      
 inv.lead_time,        
 inv.min_order,        
 inv.min_stock,        
 inv.max_stock,        
 inv.order_multiple,
 ia.field_26 ReleaseDate,
 ia.field_28 POM_date,
 ISNULL(ia.category_1,'N') Watch,
 plc_status = CASE WHEN (ia.field_28 IS NULL OR ia.field_28 > GETDATE()) AND 'N' = ISNULL(ia.category_1,'N') 
		   THEN 'Current' ELSE 'Disc' END,
 ia.category_2 Gender,
 ia.field_10 Material,
 i.vendor,
 ISNULL(ia.field_3,'') AS Color_desc, -- added 071812
 
  ReserveQty = 	ISNULL((SELECT SUM(qty) AS Reserve_qty
FROM lot_bin_stock (NOLOCK) WHERE location = inv.location AND part_no = i.part_no AND bin_no LIKE 'rr0%'),0),

-- 081414  -- add qc qty for drp and matl forecast
QcQty = ISNULL((SELECT SUM(qty) AS QcQty FROM lot_bin_recv lbr (NOLOCK) WHERE lbr.qc_flag = 'y' AND 
lbr.location = inv.location AND lbr.part_no = i.part_no),0)

, QcQty2 = ISNULL((SELECT hold_rcv FROM inv_recv ir WHERE ir.part_no = i.part_no AND ir.location = inv.location),0)


, future_ord_qty = ISNULL(bo.future_open_qty,0)

, backorder = ISNULL(bo.bo_open_qty,0)

FROM inv_master i (NOLOCK) 
INNER JOIN inv_master_add ia (NOLOCK) ON i.part_no = ia.part_no
-- inner join inventory t3 (nolock) on t1.part_no = t3.part_no
INNER JOIN cvo_inventory2 inv (NOLOCK) ON i.part_no = inv.part_no

LEFT JOIN dbo.f_get_excluded_bins_1_vw z1 ON i.part_no = z1.part_no AND inv.location = z1.location
LEFT JOIN 
(SELECT sof.part_no, sof.location, SUM(sa_stock) AS sof_qty FROM cvo_get_soft_alloc_stock_vw sof (NOLOCK) GROUP BY sof.part_no, sof.location
) sof
ON i.part_no = sof.part_no AND inv.location = sof.location

LEFT OUTER JOIN -- hard allocations
(SELECT alc.part_no, alc.location, SUM(alc.qty) alloc
FROM tdc_soft_alloc_tbl (NOLOCK) alc
WHERE order_no <>0 OR (order_no = 0 AND dest_bin = 'CUSTOM')
GROUP BY alc.part_no,
         alc.location
) alloc ON alloc.part_no = i.part_no AND alloc.location = inv.location

LEFT OUTER JOIN -- quarantine
(SELECT lb.part_no, lb.location, SUM(lb.qty) q_qty-- quarantine 
	    FROM lot_bin_stock (NOLOCK) lb
		JOIN tdc_bin_master (NOLOCK) b
		ON b.bin_no = lb.bin_no AND b.location = lb.location
		WHERE b.usage_type_code = 'QUARANTINE' 
		GROUP BY lb.part_no, lb.location
) q ON q.part_no = inv.part_no AND q.location = inv.location



LEFT OUTER JOIN
-- backorders and future order qtys
(SELECT  ol.part_no , ol.location,
        bo_open_qty = SUM(CASE WHEN o.who_entered = 'backordr' THEN ol.ordered - ol.shipped - ISNULL(ha.qty, 0) ELSE 0 end),
		future_open_qty = SUM(CASE WHEN ISNULL(sa.status, -3) = -3 THEN ol.ordered - ol.shipped - ISNULL(ha.qty, 0) ELSE 0 end)
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
        -- AND o.who_entered = 'backordr'
		-- AND ISNULL(sa.status, -3) = -3 -- future orders not yet soft allocated
        AND ol.part_type = 'P'
GROUP BY ol.part_no, ol.location
) bo
	ON bo.part_no = inv.part_no AND bo.location = inv.location

WHERE  inv.void<>'V'
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
