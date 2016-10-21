SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1	CT	01/04/11	- Add cvo_armaster_all.patterns_foo
-- v1.2	CT	04/04/11	- Add cvo_armaster_all.allow_substitutes
-- v1.3	CT	12/04/11	- Add cvo_armaster_all.commissionable and cvo_armaster_all.commission
-- v1.4	CT	02/09/11	- Add cvo_armaster_all.freight_charge
-- v1.5 CB  01/05/12	- Add ship_complete_flag for RX orders
-- v1.6	CT	05/07/12	- Add cvo_armaster_all.coop_ytd
-- v1.7	CT	11/10/12	- Add cvo_armaster_all.credit_for_returns
-- v1.8 CB  15/11/12	- Issue #966 - Add door checkbox
-- v1.9 CT	28/01/14	- Issue #1438 - Add Residential Address checkbox
-- v2.0	CT	12/03/14	- Issue #1458 - Ass category code field
-- v2.1 CB  10/07/2014 - Issue #572 - Masterpack - RX Order Consolidation
-- v2.2 CB	20/10/2016 - Add addr_valid_ind for address validation

--EXEC scm_pb_get_dw_arcust1_sp '010125'

CREATE PROCEDURE [dbo].[scm_pb_get_dw_arcust1_sp] @customer varchar(12) as
BEGIN
  SET NOCOUNT ON

  SELECT 
		a.timestamp,
		a.customer_code,   
		a.address_name customer_name,   
		a.short_name customer_short_name,   
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
		a.ship_to_code,   
		a.tax_code,   
		a.terms_code,   
		a.fob_code,   
		a.freight_code,   
		a.posting_code,   
		a.location_code,   
		a.alt_location_code,   
		a.dest_zone_code,   
		a.territory_code,   
		a.salesperson_code,   
		a.fin_chg_code,   
		a.price_code,   
		a.payment_code,   
		a.vendor_code,   
		a.affiliated_cust_code,   
		a.print_stmt_flag,   
		a.stmt_cycle_code,   
		a.inv_comment_code,   
		a.stmt_comment_code,   
		a.dunn_message_code,   
		a.note,   
		a.trade_disc_percent,   
		a.invoice_copies,   
		a.iv_substitution,   
		a.ship_to_history,   
		a.check_credit_limit,   
		a.credit_limit,   
		a.check_aging_limit,   
		a.aging_limit_bracket,   
		a.bal_fwd_flag,   
		a.ship_complete_flag,   
		a.resale_num,   
		a.db_num,   
		a.db_date,   
		a.db_credit_rating,   
		a.address_type,   
		a.late_chg_type,   
		a.valid_payer_flag,   
		a.valid_soldto_flag,   
		a.valid_shipto_flag,   
		a.payer_soldto_rel_code,   
		a.across_na_flag,   
		a.date_opened,   
		a.rate_type_home,   
		a.rate_type_oper,   
		a.limit_by_home,   
		a.nat_cur_code,   
		a.one_cur_cust,   
		a.added_by_user_name,   
		a.added_by_date,   
		a.modified_by_user_name,   
		a.modified_by_date,   
		a.url,   
		a.special_instr,   
		a.price_level,   
		a.remit_code,   
		a.forwarder_code,   
		a.freight_to_code,   
		a.route_code,   
		a.route_no,   
		a.city,   
		a.state,   
		a.postal_code,   
		a.country,
		a.ship_via_code, 
		a.country_code,
		a.tax_id_num,
		a.consolidated_invoices,
		a.writeoff_code,
		a.delivery_days,
		o1.organization_name _related_org_name,
		o2.organization_name _organization_name,
		a.extended_name,
		a.check_extendedname_flag ,
		CVO_armaster_all.customer_code,
		CVO_armaster_all.coop_eligible,
		CVO_armaster_all.coop_threshold_flag,
		CVO_armaster_all.coop_threshold_amount,
		ISNULL(dbo.CVO_armaster_all.coop_dollars,0) coop_dollars,
		CVO_armaster_all.coop_notes,
		CVO_armaster_all.coop_cust_rate_flag,
		CVO_armaster_all.coop_cust_rate,
		CVO_armaster_all.coop_dollars_prev_year,
		CVO_armaster_all.rx_carrier,
		CVO_armaster_all.bo_carrier,
		CVO_armaster_all.add_cases,
		CVO_armaster_all.add_patterns,
		CVO_armaster_all.max_dollars,
		CVO_armaster_all.metal_plastic,
		CVO_armaster_all.suns_opticals,
		CVO_armaster_all.ship_to,
		CVO_armaster_all.address_type,
		CVO_armaster_all.consol_ship_flag,
		ISNULL(CVO_armaster_all.coop_redeemed,0) coop_redeemed,
		CVO_armaster_all.patterns_foo,			-- v1.1
		cvo_armaster_all.allow_substitutes,		-- v1.2
		cvo_armaster_all.commissionable,		-- v1.3
		cvo_armaster_all.commission,			-- v1.3
		cvo_armaster_all.freight_charge,		-- v1.4
		cvo_armaster_all.ship_complete_flag_rx,	-- v1.5
		cvo_armaster_all.coop_ytd,				-- v1.6	
		cvo_armaster_all.credit_for_returns,	-- v1.7
		cvo_armaster_all.door,					-- v1.8
		cvo_armaster_all.residential_address,	-- v1.9
		cvo_armaster_all.category_code,			-- v2.0
		cvo_armaster_all.rx_consolidate,			-- v2.1
		0 addr_valid_ind -- v2.2
	FROM 
		dbo.armaster_all a (NOLOCK) 
    LEFT OUTER JOIN 
		dbo.adm_orgcustrel r (NOLOCK) 
	ON 
		r.customer_code = a.customer_code
    LEFT OUTER JOIN 
		dbo.Organization_all o1 (NOLOCK) 
	ON 
		o1.organization_id = r.related_org_id
    LEFT OUTER JOIN 
		dbo.Organization_all o2 (NOLOCK) 
	ON 
		o2.organization_id = r.organization_id
	LEFT OUTER JOIN 
		dbo.CVO_armaster_all (NOLOCK)
	ON 
		CVO_armaster_all.customer_code = a.customer_code 
		AND CVO_armaster_all.address_type = a.address_type
    WHERE 
		a.address_type = 0 
		AND a.customer_code = @customer
END
GO
GRANT EXECUTE ON  [dbo].[scm_pb_get_dw_arcust1_sp] TO [public]
GO
