SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[scm_pb_get_dw_apvend1_sp] @vendor varchar(12) as
begin
  set nocount on

SELECT a.timestamp,
	   a.vendor_code,   
	   a.address_name vendor_name,
	   a.short_name vendor_short_name,
         a.addr1,   
         a.addr2,   
         a.addr3,   
         a.addr4,   
         a.addr5,   
         a.addr6,   
         a.addr_sort1,   
         a.addr_sort2,   
         a.addr_sort3,   
         a.status_type,   
         a.attention_name,   
         a.attention_phone,   
         a.contact_name,   
         a.contact_phone,   
         a.tlx_twx,   
         a.phone_1,   
         a.phone_2,   
         a.pay_to_code,   
         a.tax_code,   
         a.terms_code,   
         a.fob_code,   
         a.posting_code,   
         a.location_code,   
         a.orig_zone_code,   
         a.customer_code,   
         a.affiliated_vend_code,   
         a.alt_vendor_code,   
         a.comment_code,   
         a.vend_class_code,   
         a.branch_code,   
         a.pay_to_hist_flag,   
         a.item_hist_flag,   
         a.credit_limit_flag,   
         a.credit_limit,   
         a.aging_limit_flag,   
         a.aging_limit,   
         a.restock_chg_flag,   
         a.restock_chg,   
         a.prc_flag,   
         a.vend_acct,   
         a.tax_id_num,   
         a.flag_1099,   
         a.exp_acct_code,   
         a.amt_max_check,   
         a.lead_time,   
         a.one_check_flag,   
         a.dup_voucher_flag,   
         a.dup_amt_flag,   
         a.code_1099,   
         a.user_trx_type_code,   
         a.payment_code,   
         a.address_type,   
         a.limit_by_home,   
         a.rate_type_home,   
         a.rate_type_oper,   
         a.nat_cur_code,   
         a.one_cur_vendor,   
         a.cash_acct_code,   
         a.state,   
         a.postal_code,   
         a.country,   
         a.freight_code,   
         a.note,   
         a.country_code,   
         a.etransmit_ind,   
         a.buying_cycle,   
         a.proc_vend_flag  ,
		 o1.organization_name _related_org_name,
		 o2.organization_name _organization_name,
		 a.extended_name,
		 a.check_extendedname_flag
	FROM apmaster_all a (nolock) 
    left outer join adm_orgvendrel r (nolock) on r.vendor_code = a.vendor_code
    left outer join Organization_all o1 (nolock) on o1.organization_id = r.related_org_id
    left outer join Organization_all o2 (nolock) on o2.organization_id = r.organization_id
    WHERE a.address_type = 0 and a.vendor_code = @vendor
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_get_dw_apvend1_sp] TO [public]
GO
