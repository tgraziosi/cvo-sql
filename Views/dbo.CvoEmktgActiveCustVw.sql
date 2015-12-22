SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[CvoEmktgActiveCustVw]
AS
SELECT 
case when ar.ship_to_code >'' then ar.customer_code+'-'+ar.ship_to_code else ar.customer_code end as extid,
ar.customer_code, ar.ship_to_code, ar.address_name, ar.short_name, 
ar.addr1, ar.addr2, ar.addr3, ar.addr4, ar.addr5, ar.addr6, ar.addr_sort1,
ar.addr_sort2, ar.addr_sort3, ar.address_type, ar.status_type, ar.attention_name, 
ar.attention_phone, ar.contact_name, ar.contact_phone, ar.tlx_twx, ar.phone_1, 
ar.phone_2, ar.tax_code, ar.terms_code, ar.fob_code, ar.freight_code, ar.posting_code, ar.location_code, ar.alt_location_code, ar.dest_zone_code, ar.territory_code, ar.salesperson_code, ar.fin_chg_code, ar.price_code, ar.payment_code, ar.vendor_code, ar.affiliated_cust_code, ar.print_stmt_flag, 
               ar.stmt_cycle_code, ar.inv_comment_code, ar.stmt_comment_code, ar.dunn_message_code, ar.note, ar.trade_disc_percent, ar.invoice_copies, ar.iv_substitution, 
               ar.ship_to_history, ar.check_credit_limit, ar.credit_limit, ar.check_aging_limit, ar.aging_limit_bracket, ar.bal_fwd_flag, ar.ship_complete_flag, ar.resale_num, 
               ar.db_num, ar.db_date, ar.db_credit_rating, ar.late_chg_type, ar.valid_payer_flag, ar.valid_soldto_flag, ar.valid_shipto_flag, ar.payer_soldto_rel_code, 
               ar.across_na_flag, ar.date_opened, ar.added_by_user_name, ar.added_by_date, ar.modified_by_user_name, ar.modified_by_date, ar.rate_type_home, 
               ar.rate_type_oper, ar.limit_by_home, ar.nat_cur_code, ar.one_cur_cust, ar.city, ar.state, ar.postal_code, ar.country, ar.remit_code, ar.forwarder_code, 
               ar.freight_to_code, ar.route_code, ar.route_no, ar.url, ar.special_instr, ar.guid, ar.price_level, ar.ship_via_code, ar.ddid, ar.so_priority_code, ar.country_code, 
               ar.tax_id_num, ar.ftp, ar.attention_email, ar.contact_email, ar.dunning_group_id, ar.consolidated_invoices, ar.writeoff_code, ar.delivery_days, ar.extended_name, 
               ar.check_extendedname_flag, Sales.rolling12net
FROM  (SELECT DISTINCT customer, ship_to, rolling12net
               FROM   dbo.cvo_rad_shipto WITH (nolock)
               WHERE 0=1 and
               (X_MONTH = MONTH(GETDATE())) AND (year = YEAR(GETDATE())) AND (rolling12net >= 2400)) AS Sales INNER JOIN
               dbo.armaster AS ar WITH (nolock) ON Sales.customer = ar.customer_code AND Sales.ship_to = ar.ship_to_code
union all 
SELECT case when ar.ship_to_code >'' then ar.customer_code+'-'+ar.ship_to_code else ar.customer_code end as extid,
ar.customer_code, ar.ship_to_code, ar.address_name, ar.short_name, 
ar.addr1, ar.addr2, ar.addr3, ar.addr4, ar.addr5, ar.addr6, ar.addr_sort1,
ar.addr_sort2, ar.addr_sort3, ar.address_type, ar.status_type, ar.attention_name, 
ar.attention_phone, ar.contact_name, ar.contact_phone, ar.tlx_twx, ar.phone_1, 
ar.phone_2, ar.tax_code, ar.terms_code, ar.fob_code, ar.freight_code, ar.posting_code, ar.location_code, ar.alt_location_code, ar.dest_zone_code, ar.territory_code, ar.salesperson_code, ar.fin_chg_code, ar.price_code, ar.payment_code, ar.vendor_code, ar.affiliated_cust_code, ar.print_stmt_flag, 
               ar.stmt_cycle_code, ar.inv_comment_code, ar.stmt_comment_code, ar.dunn_message_code, ar.note, ar.trade_disc_percent, ar.invoice_copies, ar.iv_substitution, 
               ar.ship_to_history, ar.check_credit_limit, ar.credit_limit, ar.check_aging_limit, ar.aging_limit_bracket, ar.bal_fwd_flag, ar.ship_complete_flag, ar.resale_num, 
               ar.db_num, ar.db_date, ar.db_credit_rating, ar.late_chg_type, ar.valid_payer_flag, ar.valid_soldto_flag, ar.valid_shipto_flag, ar.payer_soldto_rel_code, 
               ar.across_na_flag, ar.date_opened, ar.added_by_user_name, ar.added_by_date, ar.modified_by_user_name, ar.modified_by_date, ar.rate_type_home, 
               ar.rate_type_oper, ar.limit_by_home, ar.nat_cur_code, ar.one_cur_cust, ar.city, ar.state, ar.postal_code, ar.country, ar.remit_code, ar.forwarder_code, 
               ar.freight_to_code, ar.route_code, ar.route_no, ar.url, ar.special_instr, ar.guid, ar.price_level, ar.ship_via_code, ar.ddid, ar.so_priority_code, ar.country_code, 
               ar.tax_id_num, ar.ftp, ar.attention_email, ar.contact_email, ar.dunning_group_id, ar.consolidated_invoices, ar.writeoff_code, ar.delivery_days, ar.extended_name, 
               ar.check_extendedname_flag, 0 as rolling12net
FROM           dbo.armaster AS ar WITH (nolock) where ar.customer_code = '000010'


GO
GRANT REFERENCES ON  [dbo].[CvoEmktgActiveCustVw] TO [public]
GO
GRANT SELECT ON  [dbo].[CvoEmktgActiveCustVw] TO [public]
GO
GRANT INSERT ON  [dbo].[CvoEmktgActiveCustVw] TO [public]
GO
GRANT DELETE ON  [dbo].[CvoEmktgActiveCustVw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CvoEmktgActiveCustVw] TO [public]
GO
