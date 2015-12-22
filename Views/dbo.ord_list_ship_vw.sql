SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[ord_list_ship_vw]
AS
select 
l.order_no,
l.order_ext,
l.line_no,
l.location,
l.part_no,
l.description,
l.time_entered,
l.ordered,
l.shipped,
l.price,
l.price_type,
l.note,
l.status,
l.cost,
l.who_entered,
l.sales_comm,
l.temp_price,
l.temp_type,
l.cr_ordered,
l.cr_shipped,
l.discount,
l.uom,
l.conv_factor,
l.void,
l.void_who,
l.void_date,
l.std_cost,
l.cubic_feet,
l.printed,
l.lb_tracking,
l.labor,
l.direct_dolrs,
l.ovhd_dolrs,
l.util_dolrs,
l.taxable,
l.weight_ea,
l.qc_flag,
l.reason_code,
l.row_id,
l.qc_no,
l.rejected,
l.part_type,
l.orig_part_no,
l.back_ord_flag,
l.gl_rev_acct,
l.total_tax,
l.tax_code,
l.curr_price,
l.oper_price,
l.display_line,
l.std_direct_dolrs,
l.std_ovhd_dolrs,
l.std_util_dolrs,
l.reference_code,
l.contract,
l.agreement_id,
l.ship_to,
l.service_agreement_flag,
l.inv_available_flag,
l.create_po_flag,
l.load_group_no,
l.return_code,
l.user_count,
l.cust_po,
l.organization_id,
l.picked_dt,
l.who_picked_id,
l.printed_dt,
l.who_unpicked_id,
l.unpicked_dt,
0 protect_line
from ord_list l
GO
GRANT SELECT ON  [dbo].[ord_list_ship_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_list_ship_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ord_list_ship_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_list_ship_vw] TO [public]
GO
