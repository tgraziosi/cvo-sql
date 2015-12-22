SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_ss_item_vw] as
-- tag - 2/3/2012 - changed available calculation to match tdc_get_alloc_qntd_sp logic
SELECT         
 t3.part_no,         
 t3.description,        
 t3.location,         
 t3.in_stock,         
 qty_commit = commit_ed ,        
 sch_alloc,
 Allocated = CASE WHEN 1=1 THEN ISNULL((select SUM(qty) from tdc_soft_alloc_tbl (nolock) where part_no=t3.part_no
and location=t3.location),0)
   ELSE 0 END,        
 qty_avl = in_stock - 
	ISNULL((select SUM(qty) from tdc_soft_alloc_tbl (nolock) where part_no=t3.part_no
	and location=t3.location),0) - 
	ISNULL((SELECT sum(qty) -- quarantine 
			FROM lot_bin_stock (nolock)
		   WHERE location = t3.location
			 AND part_no = t3.part_no
			 AND bin_no in (SELECT bin_no 
    			  FROM tdc_bin_master (nolock)
    			 WHERE usage_type_code = 'QUARANTINE' 
			 AND location = t3.location)), 0)
 ,   
 qty_hold = hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr,        
 po_on_order,        
 tot_cost_ea = case when inv_cost_method = 'S' then t3.std_cost + t3.std_direct_dolrs + t3.std_ovhd_dolrs + t3.std_util_dolrs        
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end,        
 tot_ext_cost = (case when inv_cost_method = 'S' then t3.std_cost + t3.std_direct_dolrs + t3.std_ovhd_dolrs + t3.std_util_dolrs        
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end)        
   * (in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),        
 t3.bin_no,        
 t3.lead_time,        
 t3.min_order,        
 t3.min_stock,        
 t3.max_stock,        
 t3.order_multiple,        
        
 x_in_stock=in_stock,         
 x_qty_commit = commit_ed ,        
 x_sch_alloc=sch_alloc,        
 x_qty_avl = in_stock - 
	ISNULL((select SUM(qty) from tdc_soft_alloc_tbl (nolock) where part_no=t3.part_no
	and location=t3.location),0) - 
	ISNULL((SELECT sum(qty) -- quarantine 
			FROM lot_bin_stock (nolock)
		   WHERE location = t3.location
			 AND part_no = t3.part_no
			 AND bin_no in (SELECT bin_no 
    			  FROM tdc_bin_master (nolock)
    			 WHERE usage_type_code = 'QUARANTINE' 
			 AND location = t3.location)), 0)
 ,   
 x_qty_hold = hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr,        
 x_po_on_order=po_on_order,        
 x_tot_cost_ea =case when inv_cost_method = 'S' then t3.std_cost + t3.std_direct_dolrs + t3.std_ovhd_dolrs + t3.std_util_dolrs        
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end,        
 x_tot_ext_cost = (case when inv_cost_method = 'S' then t3.std_cost + t3.std_direct_dolrs + t3.std_ovhd_dolrs + t3.std_util_dolrs        
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end)         
   * (in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),        
 x_lead_time=lead_time,        
 x_min_order=min_order,        
 x_min_stock=min_stock,        
 x_max_stock=max_stock,        
 x_order_multiple=order_multiple,      
 CASE WHEN 1=1 THEN (select max(confirm_date) from releases t1      
join pur_list p on t1.po_no=p.po_no and t1.part_no=p.part_no and t1.location=p.location      
where t1.part_no=p.part_no and t1.location=p.location)      
END  AS POM      
        
         
FROM inventory t3
GO
GRANT REFERENCES ON  [dbo].[cvo_ss_item_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ss_item_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ss_item_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ss_item_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ss_item_vw] TO [public]
GO
