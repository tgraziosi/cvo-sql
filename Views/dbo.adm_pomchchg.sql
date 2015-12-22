SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[adm_pomchchg]
AS
select
h.match_ctrl_int,
h.vendor_code,
h.vendor_remit_to,
h.vendor_invoice_no,
h.date_match,
h.printed_flag,
h.vendor_invoice_date,
h.invoice_receive_date,
h.apply_date,
h.aging_date,
h.due_date,
h.discount_date,
h.amt_net,
h.amt_discount,
h.amt_tax,
h.amt_freight,
h.amt_misc,
h.amt_due,
h.match_posted_flag,
h.nat_cur_code,
h.amt_tax_included,
h.trx_type,
h.po_no,
h.location,
h.amt_gross,
h.process_group_num,
h.rate_type_home,
h.rate_type_oper,
h.curr_factor,
h.oper_factor,
h.tax_code,
h.terms_code,
h.one_time_vend_ind,
h.pay_to_addr1,
h.pay_to_addr2,
h.pay_to_addr3,
h.pay_to_addr4,
h.pay_to_addr5,
h.pay_to_addr6,
h.attention_name,
h.attention_phone,
h.amt_nonrecoverable_tax,
h.tax_freight_no_recoverable,
h.amt_nonrecoverable_incl_tax,
h.organization_id,
h.pay_to_city,
h.pay_to_state,
h.pay_to_zip,
h.pay_to_country_cd,
h.tax_valid_ind,
h.pay_to_addr_valid_ind,
h.trx_ctrl_num 
from adm_pomchchg_all h
GO
GRANT SELECT ON  [dbo].[adm_pomchchg] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_pomchchg] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_pomchchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_pomchchg] TO [public]
GO
