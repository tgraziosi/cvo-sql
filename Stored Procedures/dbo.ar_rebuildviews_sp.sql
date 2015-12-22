SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[ar_rebuildviews_sp]
AS

IF NOT EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 2000 )	--AR
	return 0


	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'arinppyt' AND type = 'V') 
		DROP VIEW arinppyt
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'artrxstlhdr' AND type = 'V') 
		DROP VIEW artrxstlhdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'artrx' AND type = 'V') 
		DROP VIEW artrx
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'arinpstlhdr' AND type = 'V') 
		DROP VIEW arinpstlhdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'arinpchg' AND type = 'V') 
		DROP VIEW arinpchg
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'arinpchg_vw' AND type = 'V') 
		DROP VIEW arinpchg_vw
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'arinpcm_vw' AND type = 'V') 
		DROP VIEW arinpcm_vw
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'artrx_alt_vw' AND type = 'V') 
		DROP VIEW artrx_alt_vw
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'armaster' AND type = 'V') 
		DROP VIEW armaster

IF (( EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1)))
	BEGIN
		EXEC(' CREATE VIEW arinppyt
			AS
			  SELECT timestamp, trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, non_ar_flag, non_ar_doc_num, 
				gl_acct_code, date_entered, date_applied, date_doc, customer_code, payment_code, payment_type, amt_payment, 
				amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp, deposit_num, bal_fwd_flag, printed_flag,
				 posted_flag, hold_flag, wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type, cash_acct_code, 
				origin_module_flag, process_group_num, source_trx_ctrl_num, source_trx_type, nat_cur_code, rate_type_home, 
				rate_type_oper, rate_home, rate_oper, amt_discount, reference_code, settlement_ctrl_num, doc_amount, org_id 
			  FROM arinppyt_all
				WHERE dbo.sm_organization_access_fn(org_id) =1
					AND   (dbo.sm_customer_vs_org_fn(customer_code , org_id )=1 OR  trx_type = 2151 )
					AND   ( 
						(dbo.sm_access_to_arinppdt_fn( trx_ctrl_num, trx_type ) =1 AND non_ar_flag =0 )
					OR
						(dbo.sm_access_to_arnonardet_fn( trx_ctrl_num, trx_type ) =1 AND non_ar_flag =1 )
						)' )
			
		EXEC( ' CREATE VIEW artrxstlhdr
			AS
			  SELECT timestamp, settlement_ctrl_num, description, date_entered, date_applied, date_posted, user_id, 
				process_group_num, doc_count_expected, doc_count_entered, doc_sum_expected, doc_sum_entered, 
				oa_cr_total_home, oa_cr_total_oper, cr_total_home, cr_total_oper, cm_total_home, cm_total_oper, 
				inv_total_home, inv_total_oper, disc_total_home, disc_total_oper, wroff_total_home, wroff_total_oper, 
				onacct_total_home, onacct_total_oper, gain_total_home, gain_total_oper, loss_total_home, loss_total_oper, 
				customer_code, nat_cur_code, batch_code, rate_type_home, rate_home, rate_type_oper, rate_oper, inv_amt_nat, 
				amt_doc_nat, amt_dist_nat, amt_on_acct, settle_flag, org_id 
			  FROM artrxstlhdr_all
				WHERE dbo.sm_organization_access_fn(org_id) =1
					AND   dbo.sm_customer_vs_org_fn(customer_code , org_id )=1 ')


		EXEC(' CREATE VIEW artrx
			AS
			  SELECT timestamp, doc_ctrl_num, trx_ctrl_num, apply_to_num, apply_trx_type, order_ctrl_num, doc_desc, 
				batch_code, trx_type, date_entered, date_posted, date_applied, date_doc, date_shipped, date_required,
				 date_due, date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, payment_code, payment_type, cust_po_num, non_ar_flag, gl_acct_code, gl_trx_id, prompt1_inp, prompt2_inp, 
				prompt3_inp, prompt4_inp, deposit_num, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_paid_to_date,
				 amt_net, amt_on_acct, amt_cost, amt_tot_chg, user_id, void_flag, paid_flag, date_paid, posted_flag, commission_flag, 
				cash_acct_code, non_ar_doc_num, purge_flag, process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, 
				amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, reference_code, ddid, org_id 
			  FROM artrx_all
			WHERE 	EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
				AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
					OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
					OR EXISTS ( SELECT 1 FROM smmycustsbymyorgsbymytokens_vw
							WHERE customer_code like customer_mask AND  organization_id = org_id )
					OR EXISTS ( SELECT 1 FROM smmyglobalcusts_vw WHERE customer_code like customer_mask )
				    )
			 ')

		EXEC (' CREATE VIEW arinpstlhdr
			AS
			  SELECT timestamp, settlement_ctrl_num, description, hold_flag, posted_flag, date_entered, date_applied, user_id, 
				process_group_num, doc_count_expected, doc_count_entered, doc_sum_expected, doc_sum_entered, cr_total_home, 
				cr_total_oper, oa_cr_total_home, oa_cr_total_oper, cm_total_home, cm_total_oper, inv_total_home, inv_total_oper, 
				disc_total_home, disc_total_oper, wroff_total_home, wroff_total_oper, onacct_total_home, onacct_total_oper, 
				gain_total_home, gain_total_oper, loss_total_home, loss_total_oper, customer_code, nat_cur_code, batch_code, 
				rate_type_home, rate_home, rate_type_oper, rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, 
				settle_flag, org_id 
			  FROM arinpstlhdr_all
				WHERE dbo.sm_organization_access_fn(org_id) =1
					AND   dbo.sm_customer_vs_org_fn(customer_code , org_id )=1 ')


		EXEC(' CREATE VIEW arinpchg
			AS
			  SELECT timestamp, trx_ctrl_num, doc_ctrl_num, doc_desc, apply_to_num, apply_trx_type, order_ctrl_num, 
				batch_code, trx_type, date_entered, date_applied, date_doc, date_shipped, date_required, date_due, 
				date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, cust_po_num, total_weight, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_net, 
				amt_paid, amt_due, amt_cost, amt_profit, next_serial_id, printed_flag, posted_flag, hold_flag, hold_desc, user_id, 
				customer_addr1, customer_addr2, customer_addr3, customer_addr4, customer_addr5, customer_addr6, customer_city, customer_state, 
				customer_postal_code, customer_country_code, ship_to_addr1, 
				ship_to_addr2, ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6, 
				ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code,
				attention_name, attention_phone, 
				amt_rem_rev, amt_rem_tax, date_recurring, location_code, process_group_num, source_trx_ctrl_num, source_trx_type, 
				amt_discount_taken, amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, 
				edit_list_flag, ddid, writeoff_code, vat_prc, org_id 
			  FROM arinpchg_all
				WHERE dbo.sm_organization_access_fn(org_id) =1
					AND   dbo.sm_customer_vs_org_fn(customer_code , org_id )=1
					AND   dbo.sm_access_to_arinpcdt_fn(trx_ctrl_num , trx_type ) =1 ')
		
		EXEC(' CREATE VIEW arinpchg_vw
				AS 
				SELECT	*
				FROM 	arinpchg
				WHERE	trx_type = 2031	 ')
				
		EXEC(' CREATE VIEW arinpcm_vw
				AS 
				SELECT	*
				FROM 	arinpchg
				WHERE	trx_type = 2032	 ')

		EXEC(' CREATE VIEW artrx_alt_vw
			AS
			  SELECT timestamp, doc_ctrl_num, trx_ctrl_num, apply_to_num, apply_trx_type, order_ctrl_num, doc_desc, 
				batch_code, trx_type, date_entered, date_posted, date_applied, date_doc, date_shipped, date_required,
				 date_due, date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, payment_code, payment_type, cust_po_num, non_ar_flag, gl_acct_code, gl_trx_id, prompt1_inp, prompt2_inp, 
				prompt3_inp, prompt4_inp, deposit_num, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_paid_to_date,
				 amt_net, amt_on_acct, amt_cost, amt_tot_chg, user_id, void_flag, paid_flag, date_paid, posted_flag, commission_flag, 
				cash_acct_code, non_ar_doc_num, purge_flag, process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, 
				amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, reference_code, ddid, org_id 
			  FROM artrx_all
			  WHERE 	EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
				AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
					OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
					OR EXISTS ( SELECT 1 FROM smmycustsbymyorgsbymytokens_vw
							WHERE customer_code like customer_mask AND  organization_id = org_id )
					OR EXISTS ( SELECT 1 FROM smmyglobalcusts_vw WHERE customer_code like customer_mask )
				    ) 
		')

		EXEC(' CREATE VIEW armaster
			AS
			SELECT 	timestamp, customer_code, ship_to_code, address_name, short_name, 
				addr1, addr2, addr3, addr4, addr5, addr6, addr_sort1, addr_sort2, addr_sort3, 
				address_type, status_type, attention_name, attention_phone, contact_name, contact_phone, 
				tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, freight_code, posting_code, 
				location_code, alt_location_code, dest_zone_code, territory_code, salesperson_code, 
				fin_chg_code, price_code, payment_code, vendor_code, affiliated_cust_code, 
				print_stmt_flag, stmt_cycle_code, inv_comment_code, stmt_comment_code, dunn_message_code, 
				note, trade_disc_percent, invoice_copies, iv_substitution, ship_to_history, check_credit_limit, 
				credit_limit, check_aging_limit, aging_limit_bracket, bal_fwd_flag, ship_complete_flag, resale_num, 
				db_num, db_date, db_credit_rating, late_chg_type, valid_payer_flag, valid_soldto_flag, valid_shipto_flag, 
				payer_soldto_rel_code, across_na_flag, date_opened, added_by_user_name, added_by_date, 
				modified_by_user_name, modified_by_date, rate_type_home, rate_type_oper, limit_by_home, 
				nat_cur_code, one_cur_cust, city, state, postal_code, country, remit_code, forwarder_code,
				freight_to_code, route_code, route_no, url, special_instr, guid, price_level, ship_via_code, 
				ddid, so_priority_code, country_code, tax_id_num, ftp, attention_email, contact_email, dunning_group_id, 
				consolidated_invoices, writeoff_code, delivery_days, extended_name, check_extendedname_flag 
			FROM armaster_all
				WHERE customer_code IN (SELECT customer_code FROM sm_customers_access_vw)
		')

	END
ELSE
	BEGIN
		EXEC(' CREATE VIEW arinppyt
			AS
			  SELECT timestamp, trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, non_ar_flag, non_ar_doc_num, 
				gl_acct_code, date_entered, date_applied, date_doc, customer_code, payment_code, payment_type, amt_payment, 
				amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp, deposit_num, bal_fwd_flag, printed_flag,
				 posted_flag, hold_flag, wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type, cash_acct_code, 
				origin_module_flag, process_group_num, source_trx_ctrl_num, source_trx_type, nat_cur_code, rate_type_home, 
				rate_type_oper, rate_home, rate_oper, amt_discount, reference_code, settlement_ctrl_num, doc_amount, org_id 
			  FROM arinppyt_all ')
			
		EXEC( ' CREATE VIEW artrxstlhdr
			AS
			  SELECT timestamp, settlement_ctrl_num, description, date_entered, date_applied, date_posted, user_id, 
				process_group_num, doc_count_expected, doc_count_entered, doc_sum_expected, doc_sum_entered, 
				oa_cr_total_home, oa_cr_total_oper, cr_total_home, cr_total_oper, cm_total_home, cm_total_oper, 
				inv_total_home, inv_total_oper, disc_total_home, disc_total_oper, wroff_total_home, wroff_total_oper, 
				onacct_total_home, onacct_total_oper, gain_total_home, gain_total_oper, loss_total_home, loss_total_oper, 
				customer_code, nat_cur_code, batch_code, rate_type_home, rate_home, rate_type_oper, rate_oper, inv_amt_nat, 
				amt_doc_nat, amt_dist_nat, amt_on_acct, settle_flag, org_id 
			  FROM artrxstlhdr_all ')


		EXEC(' CREATE VIEW artrx
			AS
			  SELECT timestamp, doc_ctrl_num, trx_ctrl_num, apply_to_num, apply_trx_type, order_ctrl_num, doc_desc, 
				batch_code, trx_type, date_entered, date_posted, date_applied, date_doc, date_shipped, date_required,
				 date_due, date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, payment_code, payment_type, cust_po_num, non_ar_flag, gl_acct_code, gl_trx_id, prompt1_inp, prompt2_inp, 
				prompt3_inp, prompt4_inp, deposit_num, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_paid_to_date,
				 amt_net, amt_on_acct, amt_cost, amt_tot_chg, user_id, void_flag, paid_flag, date_paid, posted_flag, commission_flag, 
				cash_acct_code, non_ar_doc_num, purge_flag, process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, 
				amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, reference_code, ddid, org_id 
			  FROM artrx_all ')

		EXEC (' CREATE VIEW arinpstlhdr
			AS
			  SELECT timestamp, settlement_ctrl_num, description, hold_flag, posted_flag, date_entered, date_applied, user_id, 
				process_group_num, doc_count_expected, doc_count_entered, doc_sum_expected, doc_sum_entered, cr_total_home, 
				cr_total_oper, oa_cr_total_home, oa_cr_total_oper, cm_total_home, cm_total_oper, inv_total_home, inv_total_oper, 
				disc_total_home, disc_total_oper, wroff_total_home, wroff_total_oper, onacct_total_home, onacct_total_oper, 
				gain_total_home, gain_total_oper, loss_total_home, loss_total_oper, customer_code, nat_cur_code, batch_code, 
				rate_type_home, rate_home, rate_type_oper, rate_oper, inv_amt_nat, amt_doc_nat, amt_dist_nat, amt_on_acct, 
				settle_flag, org_id 
			  FROM arinpstlhdr_all ')


		EXEC(' CREATE VIEW arinpchg
			AS
			  SELECT timestamp, trx_ctrl_num, doc_ctrl_num, doc_desc, apply_to_num, apply_trx_type, order_ctrl_num, 
				batch_code, trx_type, date_entered, date_applied, date_doc, date_shipped, date_required, date_due, 
				date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, cust_po_num, total_weight, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_net, 
				amt_paid, amt_due, amt_cost, amt_profit, next_serial_id, printed_flag, posted_flag, hold_flag, hold_desc, user_id, 
				customer_addr1, customer_addr2, customer_addr3, customer_addr4, customer_addr5, customer_addr6,  customer_city, customer_state, 
				customer_postal_code, customer_country_code, ship_to_addr1, 
				ship_to_addr2, ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6,
				ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, 
				attention_name, attention_phone, 
				amt_rem_rev, amt_rem_tax, date_recurring, location_code, process_group_num, source_trx_ctrl_num, source_trx_type, 
				amt_discount_taken, amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, 
				edit_list_flag, ddid, writeoff_code, vat_prc, org_id 
			  FROM arinpchg_all ')
		
		EXEC(' CREATE VIEW arinpchg_vw
				AS 
				SELECT	*
				FROM 	arinpchg
				WHERE	trx_type = 2031	 ')
				
		EXEC(' CREATE VIEW arinpcm_vw
				AS 
				SELECT	*
				FROM 	arinpchg
				WHERE	trx_type = 2032	 ')

		EXEC(' CREATE VIEW artrx_alt_vw
			AS
			  SELECT timestamp, doc_ctrl_num, trx_ctrl_num, apply_to_num, apply_trx_type, order_ctrl_num, doc_desc, 
				batch_code, trx_type, date_entered, date_posted, date_applied, date_doc, date_shipped, date_required,
				 date_due, date_aging, customer_code, ship_to_code, salesperson_code, territory_code, comment_code, fob_code, 
				freight_code, terms_code, fin_chg_code, price_code, dest_zone_code, posting_code, recurring_flag, recurring_code, 
				tax_code, payment_code, payment_type, cust_po_num, non_ar_flag, gl_acct_code, gl_trx_id, prompt1_inp, prompt2_inp, 
				prompt3_inp, prompt4_inp, deposit_num, amt_gross, amt_freight, amt_tax, amt_tax_included, amt_discount, amt_paid_to_date,
				 amt_net, amt_on_acct, amt_cost, amt_tot_chg, user_id, void_flag, paid_flag, date_paid, posted_flag, commission_flag, 
				cash_acct_code, non_ar_doc_num, purge_flag, process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, 
				amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, reference_code, ddid, org_id 
			  FROM artrx_all ')

		EXEC(' CREATE VIEW armaster
			AS
			SELECT 	timestamp, customer_code, ship_to_code, address_name, short_name, 
				addr1, addr2, addr3, addr4, addr5, addr6, addr_sort1, addr_sort2, addr_sort3, 
				address_type, status_type, attention_name, attention_phone, contact_name, contact_phone, 
				tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, freight_code, posting_code, 
				location_code, alt_location_code, dest_zone_code, territory_code, salesperson_code, 
				fin_chg_code, price_code, payment_code, vendor_code, affiliated_cust_code, 
				print_stmt_flag, stmt_cycle_code, inv_comment_code, stmt_comment_code, dunn_message_code, 
				note, trade_disc_percent, invoice_copies, iv_substitution, ship_to_history, check_credit_limit, 
				credit_limit, check_aging_limit, aging_limit_bracket, bal_fwd_flag, ship_complete_flag, resale_num, 
				db_num, db_date, db_credit_rating, late_chg_type, valid_payer_flag, valid_soldto_flag, valid_shipto_flag, 
				payer_soldto_rel_code, across_na_flag, date_opened, added_by_user_name, added_by_date, 
				modified_by_user_name, modified_by_date, rate_type_home, rate_type_oper, limit_by_home, 
				nat_cur_code, one_cur_cust, city, state, postal_code, country, remit_code, forwarder_code,
				freight_to_code, route_code, route_no, url, special_instr, guid, price_level, ship_via_code, 
				ddid, so_priority_code, country_code, tax_id_num, ftp, attention_email, contact_email, dunning_group_id, 
				consolidated_invoices, writeoff_code, delivery_days, extended_name, check_extendedname_flag 
			FROM armaster_all
		')
	END


	EXEC ( 'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON arinppyt TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON artrxstlhdr TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON artrx TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON arinpstlhdr TO PUBLIC 
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON arinpchg TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON arinpchg_vw TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON arinpcm_vw TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON artrx_alt_vw TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON armaster TO PUBLIC ')   
GO
GRANT EXECUTE ON  [dbo].[ar_rebuildviews_sp] TO [public]
GO
