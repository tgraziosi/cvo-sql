SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[produce] as
select
p.prod_no,
p.prod_ext,
p.prod_date,
p.part_type,
p.part_no,
p.location,
p.qty,
p.prod_type,
p.sch_no,
p.down_time,
p.shift,
p.who_entered,
p.qty_scheduled,
p.qty_scheduled_orig,
p.build_to_bom,
p.date_entered,
p.status,
p.project_key,
p.sch_flag,
p.staging_area,
p.sch_date,
p.conv_factor,
p.uom,
p.printed,
p.void,
p.void_who,
p.void_date,
p.note,
p.end_sch_date,
p.tot_avg_cost,
p.tot_direct_dolrs,
p.tot_ovhd_dolrs,
p.tot_util_dolrs,
p.tot_labor,
p.est_avg_cost,
p.est_direct_dolrs,
p.est_ovhd_dolrs,
p.est_util_dolrs,
p.est_labor,
p.tot_prod_avg_cost,
p.tot_prod_direct_dolrs,
p.tot_prod_ovhd_dolrs,
p.tot_prod_util_dolrs,
p.tot_prod_labor,
p.scrapped,
p.cost_posted,
p.qc_flag,
p.order_no,
p.est_no,
p.description,
p.row_id,
p.hold_flag,
p.hold_code,
p.posting_code,
p.fg_cost_ind,
p.sub_com_cost_ind,
p.resource_cost_ind,
p.orig_prod_no,
p.orig_prod_ext,
p.custom_plan,
p.bom_rev,
p.wopick_ctrl_num
from produce_all p (nolock),
locations l (nolock)
where p.location = l.location
GO
GRANT REFERENCES ON  [dbo].[produce] TO [public]
GO
GRANT SELECT ON  [dbo].[produce] TO [public]
GO
GRANT INSERT ON  [dbo].[produce] TO [public]
GO
GRANT DELETE ON  [dbo].[produce] TO [public]
GO
GRANT UPDATE ON  [dbo].[produce] TO [public]
GO
