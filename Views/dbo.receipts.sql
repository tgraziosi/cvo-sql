SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[receipts]
as
select
r.receipt_no,
r.po_no,
r.part_no,
r.sku_no,
r.location,
r.release_date,
r.recv_date,
r.part_type,
r.unit_cost,
r.quantity,
r.vendor,
r.unit_measure,
r.prod_no,
r.freight_cost,
r.account_no,
r.status,
r.ext_cost,
r.who_entered,
r.vend_inv_no,
r.conv_factor,
r.pro_number,
r.bl_no,
r.lb_tracking,
r.freight_flag,
r.freight_vendor,
r.freight_inv_no,
r.freight_account,
r.freight_unit,
r.voucher_no,
r.note,
r.po_key,
r.qc_flag,
r.qc_no,
r.rejected,
r.over_flag,
r.std_cost,
r.std_direct_dolrs,
r.std_ovhd_dolrs,
r.std_util_dolrs,
r.nat_curr,
r.oper_factor,
r.curr_factor,
r.oper_cost,
r.curr_cost,
r.project1,
r.project2,
r.project3,
r.tax_included,
r.po_line,
r.return_code,
r.receipt_batch_no,
r.amt_nonrecoverable_tax,
r.organization_id
from receipts_all r,
locations l
where r.location = l.location
GO
GRANT REFERENCES ON  [dbo].[receipts] TO [public]
GO
GRANT SELECT ON  [dbo].[receipts] TO [public]
GO
GRANT INSERT ON  [dbo].[receipts] TO [public]
GO
GRANT DELETE ON  [dbo].[receipts] TO [public]
GO
GRANT UPDATE ON  [dbo].[receipts] TO [public]
GO
