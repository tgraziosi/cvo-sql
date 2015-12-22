SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[pur_list_rcvg_vw]
as
select
p.po_no,
p.part_no,
p.location,
p.type,
p.vend_sku,
p.account_no,
p.description,
p.unit_cost,
p.unit_measure,
p.note,
p.rel_date,
p.qty_ordered,
p.qty_received,
p.who_entered,
p.status,
p.ext_cost,
p.conv_factor,
p.void,
p.void_who,
p.void_date,
p.lb_tracking,
p.line,
p.taxable,
p.prev_qty,
p.po_key,
p.weight_ea,
p.row_id,
p.tax_code,
p.curr_factor,
p.oper_factor,
p.total_tax,
p.curr_cost,
p.oper_cost,
p.reference_code,
p.project1,
p.project2,
p.project3,
p.tolerance_code,
p.shipto_code,
p.receiving_loc,
p.shipto_name,
p.addr1,
p.addr2,
p.addr3,
p.addr4,
p.addr5,
p.receipt_batch_no,
p.organization_id,
p.city,
p.state,
p.zip,
p.country_cd ,
p.addr_valid_ind

from pur_list p, locations l (nolock)
where p.receiving_loc = l.location
GO
GRANT REFERENCES ON  [dbo].[pur_list_rcvg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pur_list_rcvg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pur_list_rcvg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pur_list_rcvg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pur_list_rcvg_vw] TO [public]
GO
