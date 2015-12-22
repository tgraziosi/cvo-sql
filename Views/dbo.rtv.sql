SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[rtv]
AS
select
r.rtv_no,
r.vendor_no,
r.location,
r.status,
r.printed,
r.date_of_order,
r.date_order_due,
r.vend_rma_no,
r.ship_to_no,
r.ship_name,
r.ship_address1,
r.ship_address2,
r.ship_address3,
r.ship_address4,
r.ship_address5,
r.ship_city,
r.ship_state,
r.ship_zip,
r.ship_via,
r.fob,
r.terms,
r.attn,
r.rtv_type,
r.who_entered,
r.total_amt_order,
r.restock_fee,
r.freight,
r.date_to_pay,
r.vend_inv_no,
r.freight_flag,
r.freight_vendor,
r.freight_inv_no,
r.void,
r.void_who,
r.void_date,
r.post_to_ap,
r.note,
r.tax_code,
r.tax_amt,
r.currency_key,
r.curr_factor,
r.rate_type_home,
r.rate_type_oper,
r.oper_factor,
r.posting_code,
r.apply_date,
r.doc_date,
r.match_ctrl_int,
r.amt_tax_included,
r.organization_id,
r.ship_to_country_cd ,
r.tax_valid_ind ,
r.addr_valid_ind
from rtv_all r
GO
GRANT REFERENCES ON  [dbo].[rtv] TO [public]
GO
GRANT SELECT ON  [dbo].[rtv] TO [public]
GO
GRANT INSERT ON  [dbo].[rtv] TO [public]
GO
GRANT DELETE ON  [dbo].[rtv] TO [public]
GO
GRANT UPDATE ON  [dbo].[rtv] TO [public]
GO
