SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[orders_entry_vw]
AS
select 
o.order_no,
o.ext,
o.cust_code,
o.ship_to,
o.req_ship_date,
o.sch_ship_date,
o.date_shipped,
o.date_entered,
o.cust_po,
o.who_entered,
o.status,
o.attention,
o.phone,
o.terms,
o.routing,
o.special_instr,
o.invoice_date,
o.total_invoice,
o.total_amt_order,
o.salesperson,
o.tax_id,
o.tax_perc,
o.invoice_no,
o.fob,
o.freight,
o.printed,
o.discount,
o.label_no,
o.cancel_date,
o.new,
o.ship_to_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_add_3,
o.ship_to_add_4,
o.ship_to_add_5,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
o.ship_to_country,
o.ship_to_region,
o.cash_flag,
o.type,
o.back_ord_flag,
o.freight_allow_pct,
o.route_code,
o.route_no,
o.date_printed,
o.date_transfered,
o.cr_invoice_no,
o.who_picked,
o.note,
o.void,
o.void_who,
o.void_date,
o.changed,
o.remit_key,
o.forwarder_key,
o.freight_to,
o.sales_comm,
o.freight_allow_type,
o.cust_dfpa,
o.location,
o.total_tax,
o.total_discount,
o.f_note,
o.invoice_edi,
o.edi_batch,
o.post_edi_date,
o.blanket,
o.gross_sales,
o.load_no,
o.curr_key,
o.curr_type,
o.curr_factor,
o.bill_to_key,
o.oper_factor,
o.tot_ord_tax,
o.tot_ord_disc,
o.tot_ord_freight,
o.posting_code,
o.rate_type_home,
o.rate_type_oper,
o.reference_code,
o.hold_reason,
o.dest_zone_code,
o.orig_no,
o.orig_ext,
o.tot_tax_incl,
o.process_ctrl_num,
o.batch_code,
o.tot_ord_incl,
o.barcode_status,
o.multiple_flag,
o.so_priority_code,
o.FO_order_no,
o.blanket_amt,
o.user_priority,
o.user_category,
o.from_date,
o.to_date,
o.consolidate_flag,
o.proc_inv_no,
o.sold_to_addr1,
o.sold_to_addr2,
o.sold_to_addr3,
o.sold_to_addr4,
o.sold_to_addr5,
o.sold_to_addr6,
o.user_code,
o.user_def_fld1,
o.user_def_fld2,
o.user_def_fld3,
o.user_def_fld4,
o.user_def_fld5,
o.user_def_fld6,
o.user_def_fld7,
o.user_def_fld8,
o.user_def_fld9,
o.user_def_fld10,
o.user_def_fld11,
o.user_def_fld12,
o.eprocurement_ind,
o.sold_to,
o.sopick_ctrl_num,
o.organization_id,
o.ship_to_country_cd,
o.sold_to_city,
o.sold_to_state,
o.sold_to_zip,
o.sold_to_country_cd ,
o.tax_valid_ind ,
o.addr_valid_ind
from orders o
GO
GRANT SELECT ON  [dbo].[orders_entry_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[orders_entry_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[orders_entry_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[orders_entry_vw] TO [public]
GO
