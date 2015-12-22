SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adavl_vw] as


SELECT 
	part_no, 
	description,
	location, 
	in_stock, 
	qty_commit = commit_ed ,
	sch_alloc,
	qty_avl = in_stock - sch_alloc- commit_ed,
	qty_hold = hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr,
	po_on_order,
	tot_cost_ea = case when inv_cost_method = 'S' then std_cost + std_direct_dolrs + std_ovhd_dolrs + std_util_dolrs
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end,
	tot_ext_cost = (case when inv_cost_method = 'S' then std_cost + std_direct_dolrs + std_ovhd_dolrs + std_util_dolrs
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end)
			* (in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),
	bin_no,
	lead_time,
	min_order,
	min_stock,
	max_stock,
	order_multiple,

	x_in_stock=in_stock, 
	x_qty_commit = commit_ed ,
	x_sch_alloc=sch_alloc,
	x_qty_avl = in_stock - sch_alloc- commit_ed,
	x_qty_hold = hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr,
	x_po_on_order=po_on_order,
	x_tot_cost_ea =case when inv_cost_method = 'S' then std_cost + std_direct_dolrs + std_ovhd_dolrs + std_util_dolrs
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end,
	x_tot_ext_cost = (case when inv_cost_method = 'S' then std_cost + std_direct_dolrs + std_ovhd_dolrs + std_util_dolrs
    else avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs end) 
			* (in_stock + hold_qty+hold_mfg+hold_ord+hold_rcv+hold_xfr),
	x_lead_time=lead_time,
	x_min_order=min_order,
	x_min_stock=min_stock,
	x_max_stock=max_stock,
	x_order_multiple=order_multiple

	
FROM inventory 

 
GO
GRANT REFERENCES ON  [dbo].[adavl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adavl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adavl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adavl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adavl_vw] TO [public]
GO
