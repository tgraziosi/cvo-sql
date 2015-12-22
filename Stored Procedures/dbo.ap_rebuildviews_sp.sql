SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO








                                                

CREATE PROCEDURE [dbo].[ap_rebuildviews_sp]
AS

IF NOT EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 4000 )	--AP
	return 0

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apdmhdr' AND type = 'V') 
		DROP VIEW apdmhdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apinpchg' AND type = 'V') 
		DROP VIEW apinpchg
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apinppyt' AND type = 'V') 
		DROP VIEW apinppyt
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apinpstl' AND type = 'V') 
		DROP VIEW apinpstl
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'appahdr' AND type = 'V') 
		DROP VIEW appahdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'appyhdr' AND type = 'V') 
		DROP VIEW appyhdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'appystl' AND type = 'V')
		DROP VIEW appystl
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apvahdr' AND type = 'V')
		DROP VIEW apvahdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apvohdr' AND type = 'V')
		DROP VIEW apvohdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'apmaster' AND type = 'V')
		DROP VIEW apmaster
-- Add  atmtchdr, epmchhdr		
        IF EXISTS (SELECT name FROM sysobjects WHERE name = 'atmtchdr' AND type = 'V') 
	        DROP VIEW atmtchdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'epmchhdr' AND type = 'V') 
	        DROP VIEW epmchhdr		
		
		
IF (( EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1)))
	BEGIN
		EXEC ( 'CREATE VIEW apdmhdr
				AS
				 SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, 
					vend_order_num, ticket_num, date_posted, date_applied, date_doc, date_entered, posting_code, vendor_code, 
					pay_to_code, branch_code, class_code, comment_code, fob_code, tax_code, state_flag, amt_gross, amt_discount, 
					amt_freight, amt_tax, amt_misc, amt_net, amt_restock, amt_tax_included, frt_calc_tax, doc_desc, user_id, 
					journal_ctrl_num, intercompany_flag, process_ctrl_num, currency_code, rate_type_home, rate_type_oper, 
					rate_home, rate_oper, org_id, tax_freight_no_recoverable 
				  FROM apdmhdr_all
				  WHERE EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
					OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR	
					(	EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
						AND (	EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
							WHERE vendor_code like vendor_mask AND  organization_id = org_id )
							OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
						) 
					) ') 

		EXEC (' CREATE VIEW apinpchg
			AS
			SELECT timestamp, trx_ctrl_num, trx_type, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, 
				po_ctrl_num, vend_order_num, ticket_num, date_applied, date_aging, date_due, date_doc, 
				date_entered, date_received, date_required, date_recurring, date_discount, posting_code, 
				vendor_code, pay_to_code, branch_code, class_code, approval_code, comment_code, fob_code, 
				terms_code, tax_code, recurring_code, location_code, payment_code, times_accrued, accrual_flag, 
				drop_ship_flag, posted_flag, hold_flag, add_cost_flag, approval_flag, recurring_flag, one_time_vend_flag, 
				one_check_flag, amt_gross, amt_discount, amt_tax, amt_freight, amt_misc, amt_net, amt_paid, amt_due, 
				amt_restock, amt_tax_included, frt_calc_tax, doc_desc, hold_desc, user_id, next_serial_id, pay_to_addr1, 
				pay_to_addr2, pay_to_addr3, pay_to_addr4, pay_to_addr5, pay_to_addr6, pay_to_city, pay_to_state, 
				pay_to_postal_code, pay_to_country_code, attention_name, attention_phone, 
				intercompany_flag, company_code, cms_flag, process_group_num, nat_cur_code, rate_type_home, rate_type_oper, 
				rate_home, rate_oper, net_original_amt, org_id, tax_freight_no_recoverable
			FROM	apinpchg_all
			WHERE 	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )  OR
				EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR
			(	EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = apinpchg_all.org_id )
				AND (	EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
							WHERE vendor_code like vendor_mask AND  organization_id = org_id )
					OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
				    )
				AND NOT EXISTS (SELECT  1
					FROM apinpcdt d
					INNER JOIN glco co on rec_company_code = co.company_code
					WHERE	d.trx_ctrl_num = apinpchg_all.trx_ctrl_num
					AND d.trx_type = apinpchg_all.trx_type 
					AND not exists (select 1 from org_org_vw where org_id = organization_id))
			) ')


		EXEC (' CREATE VIEW apinppyt
			AS
			SELECT timestamp, trx_ctrl_num, trx_type, doc_ctrl_num, trx_desc, batch_code, cash_acct_code, 
				date_entered, date_applied, date_doc, vendor_code, pay_to_code, approval_code, payment_code, 
				payment_type, amt_payment, amt_on_acct, posted_flag, printed_flag, hold_flag, approval_flag, 
				gen_id, user_id, void_type, amt_disc_taken, print_batch_num, company_code, process_group_num,
				nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, payee_name, settlement_ctrl_num, 
				doc_amount, org_id 
			FROM apinppyt_all
			WHERE 	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 ) OR
				EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR 
				(
					EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = apinppyt_all.org_id )
					AND (	EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
								WHERE vendor_code like vendor_mask AND  organization_id = org_id )
						OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
							)
					AND NOT EXISTS (SELECT  1
						FROM apinppdt d				
						WHERE	d.trx_ctrl_num = apinppyt_all.trx_ctrl_num
						AND d.trx_type = apinppyt_all.trx_type 
						AND not exists (select 1 from org_org_vw where org_id = organization_id))
				) ')

		EXEC (' CREATE VIEW apinpstl
			AS
			SELECT timestamp, settlement_ctrl_num, vendor_code, pay_to_code, hold_flag, date_entered, date_applied, user_id, batch_code, 
			process_group_num, state_flag, disc_total_home, disc_total_oper, debit_memo_total_home, debit_memo_total_oper, on_acct_pay_total_home, 
			on_acct_pay_total_oper, payments_total_home,payments_total_oper, put_on_acct_total_home, put_on_acct_total_oper, gain_total_home, 
			gain_total_oper, loss_total_home, loss_total_oper, description,nat_cur_code, doc_count_expected, doc_count_entered, doc_sum_expected, 
			doc_sum_entered, vo_total_home, vo_total_oper, rate_type_home, rate_home,rate_type_oper, rate_oper, vo_amt_nat, amt_doc_nat, amt_dist_nat, 
			amt_on_acct, org_id
			FROM apinpstl_all
			WHERE 	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 ) OR 
				EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR 
				(	EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = apinpstl_all.org_id )
					AND (	
						EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
							WHERE vendor_code like vendor_mask AND  organization_id = org_id )
						OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
					) 
				) ')
		
		EXEC (' CREATE VIEW appahdr
		AS
			SELECT timestamp, trx_ctrl_num, doc_ctrl_num, batch_code, date_posted, 
			      date_applied, date_entered, cash_acct_code, state_flag, void_flag,
			      doc_desc, user_id, journal_ctrl_num, process_ctrl_num, org_id
			FROM appahdr_all
				 WHERE EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = appahdr_all.org_id ) ')
		
		EXEC ('CREATE VIEW appyhdr
				AS
					SELECT timestamp, trx_ctrl_num, doc_ctrl_num, batch_code, date_posted, date_applied, date_doc, 
						date_entered, vendor_code, pay_to_code, approval_code, cash_acct_code, payment_code, state_flag, void_flag, 
						amt_net, amt_discount, amt_on_acct, payment_type, doc_desc, user_id, journal_ctrl_num, print_batch_num, 
						process_ctrl_num, currency_code, rate_type_home, rate_type_oper, rate_home, rate_oper, payee_name, 
						settlement_ctrl_num, org_id 
					FROM appyhdr_all
					WHERE 	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 ) OR 
						EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR 
						(
							EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
							AND (	
								EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
										WHERE vendor_code like vendor_mask AND  organization_id = org_id )
								OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
							)
						) ')
		
		EXEC (' CREATE VIEW appystl
			AS
			 SELECT timestamp, settlement_ctrl_num, vendor_code , pay_to_code, date_entered, date_applied, user_id, batch_code, process_group_num, 
			state_flag, disc_total_home, disc_total_oper, debit_memo_total_home, debit_memo_total_oper, on_acct_pay_total_home, on_acct_pay_total_oper, 
			payments_total_home, payments_total_oper, put_on_acct_total_home, put_on_acct_total_oper, gain_total_home, gain_total_oper, loss_total_home, 
			loss_total_oper, org_id
			FROM appystl_all
			WHERE 	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 ) OR 
					EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR 
					(
					EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
					AND (	
						EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
								WHERE vendor_code like vendor_mask AND  organization_id = org_id )
						OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
						) 
					)')
		
		EXEC (' CREATE VIEW apvahdr
			AS
			SELECT timestamp, trx_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, vend_order_num, ticket_num, 
			date_posted, date_applied, date_aging, date_due, date_doc, date_entered, date_received, date_required, date_discount, fob_code, terms_code, 
			state_flag, doc_desc, user_id, journal_ctrl_num, process_ctrl_num, org_id
			FROM apvahdr_all
				 WHERE 	EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id ) ')
		
		EXEC (' CREATE VIEW apvohdr
				AS
				 SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num,
					 vend_order_num, ticket_num, date_posted, date_applied, date_aging, date_due, date_doc, date_entered,
					 date_received, date_required, date_paid, date_discount, posting_code, vendor_code, pay_to_code,
					 branch_code, class_code, approval_code, comment_code, fob_code, terms_code, tax_code, recurring_code, 
					 payment_code, state_flag, paid_flag, recurring_flag, one_time_vend_flag, one_check_flag, accrual_flag, 
					 times_accrued, amt_gross, amt_discount, amt_freight, amt_tax, amt_misc, amt_net, amt_paid_to_date, 
					 amt_tax_included, frt_calc_tax, doc_desc, user_id, journal_ctrl_num, payment_hold_flag, intercompany_flag, 
					 process_ctrl_num, currency_code, rate_type_home, rate_type_oper, rate_home, rate_oper, net_original_amt, org_id,
					 tax_freight_no_recoverable 
				 FROM apvohdr_all
				 WHERE 	
					EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
					AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
						OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
						OR EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
								WHERE vendor_code like vendor_mask AND  organization_id = org_id )
						OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
							) ')

		EXEC ('CREATE VIEW apmaster
				AS
				SELECT timestamp, vendor_code, pay_to_code, address_name, short_name, 
					addr1, addr2, addr3, addr4, addr5, addr6, addr_sort1, addr_sort2, addr_sort3, 
					address_type, status_type, attention_name, attention_phone, contact_name, contact_phone, 
					tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, posting_code, location_code, 
					orig_zone_code, customer_code, affiliated_vend_code, alt_vendor_code, comment_code, vend_class_code,
					branch_code, pay_to_hist_flag, item_hist_flag, credit_limit_flag, credit_limit, aging_limit_flag, 
					aging_limit, restock_chg_flag, restock_chg, prc_flag, vend_acct, tax_id_num, flag_1099, exp_acct_code,
					amt_max_check, lead_time, doc_ctrl_num, one_check_flag, dup_voucher_flag, dup_amt_flag, code_1099, 
					user_trx_type_code, payment_code, limit_by_home, rate_type_home, rate_type_oper, nat_cur_code, one_cur_vendor,
					cash_acct_code, city, state, postal_code, country, freight_code, url, note, country_code, ftp, attention_email, 
					contact_email, etransmit_ind, vo_hold_flag, po_item_flag, buying_cycle, proc_vend_flag, extended_name, check_extendedname_flag 
				FROM apmaster_all
					WHERE vendor_code IN (SELECT vendor_code FROM sm_vendors_access_vw) ' )
		
		IF EXISTS (SELECT name FROM sysobjects WHERE name = 'atmtchdr_all') 
	        EXEC (" CREATE VIEW atmtchdr
			AS
			SELECT 	timestamp, 	invoice_no, 	vendor_code, 	amt_net, 	date_doc, 
			date_discount, 	nat_cur_code, 	status, 	date_posted, 	date_imported, 
			num_failed, 	date_failed, 	source_module, 	error_desc, 	amt_tax, 	
			amt_discount, 	amt_freight, 	amt_misc, 	org_id 
			FROM atmtchdr_all
			 WHERE 	(
				 EXISTS( SELECT 1 FROM Organization WHERE organization_id = org_id )
				AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
					OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
					OR EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
							WHERE vendor_code like vendor_mask AND  organization_id = org_id )
					OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
						) 
				)
			 OR  	( 	
				LEN(LTRIM(RTRIM(ISNULL(org_id,'')))) = 0  
				AND vendor_code IN  (SELECT vendor_code FROM sm_vendors_access_vw)
				 )
	             ") 
	             
              IF EXISTS (SELECT name FROM sysobjects WHERE name = 'epmchhdr_all') 
		EXEC (' CREATE VIEW epmchhdr
			AS
			SELECT  timestamp, 	match_ctrl_num, 	vendor_code, 		vendor_remit_to, 
				vendor_invoice_no, date_match, 		tolerance_hold_flag, 	tolerance_approval_flag, 
				validated_flag, vendor_invoice_date, 	invoice_receive_date, 	apply_date, 
				aging_date, 	due_date, 		discount_date, 		amt_net, 
				amt_discount, 	amt_tax, 		amt_freight, 		amt_misc, 
				amt_due, 	match_posted_flag, 	amt_tax_included, 	trx_ctrl_num, 	
				nat_cur_code, 	rate_type_home, 	rate_type_oper, 	rate_home, 
				rate_oper, 	batch_code, 		org_id 
			FROM  epmchhdr_all
			WHERE 	EXISTS( SELECT 1 FROM Organization WHERE organization_id = org_id )
					AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
						OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
						OR EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
								WHERE vendor_code like vendor_mask AND  organization_id = org_id )
						OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask )
							)
			AND NOT EXISTS (SELECT 1 FROM epmchdtl d 
					INNER JOIN glchart gl ON gl.account_code = d.account_code
					WHERE epmchhdr_all.match_ctrl_num = d.match_ctrl_num 
					AND not exists (select 1 from org_org_vw where org_id = organization_id))           
	              ') 					
					


	END
ELSE
	BEGIN
		EXEC ( 'CREATE VIEW apdmhdr
				AS
				 SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, 
					vend_order_num, ticket_num, date_posted, date_applied, date_doc, date_entered, posting_code, vendor_code, 
					pay_to_code, branch_code, class_code, comment_code, fob_code, tax_code, state_flag, amt_gross, amt_discount, 
					amt_freight, amt_tax, amt_misc, amt_net, amt_restock, amt_tax_included, frt_calc_tax, doc_desc, user_id, 
					journal_ctrl_num, intercompany_flag, process_ctrl_num, currency_code, rate_type_home, rate_type_oper, 
					rate_home, rate_oper, org_id, tax_freight_no_recoverable 
				  FROM apdmhdr_all ') 

		EXEC (' CREATE VIEW apinpchg
		AS
			SELECT timestamp, trx_ctrl_num, trx_type, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, 
				po_ctrl_num, vend_order_num, ticket_num, date_applied, date_aging, date_due, date_doc, 
				date_entered, date_received, date_required, date_recurring, date_discount, posting_code, 
				vendor_code, pay_to_code, branch_code, class_code, approval_code, comment_code, fob_code, 
				terms_code, tax_code, recurring_code, location_code, payment_code, times_accrued, accrual_flag, 
				drop_ship_flag, posted_flag, hold_flag, add_cost_flag, approval_flag, recurring_flag, one_time_vend_flag, 
				one_check_flag, amt_gross, amt_discount, amt_tax, amt_freight, amt_misc, amt_net, amt_paid, amt_due, 
				amt_restock, amt_tax_included, frt_calc_tax, doc_desc, hold_desc, user_id, next_serial_id, pay_to_addr1, 
				pay_to_addr2, pay_to_addr3, pay_to_addr4, pay_to_addr5, pay_to_addr6, pay_to_city, pay_to_state, 
					pay_to_postal_code, pay_to_country_code, attention_name, attention_phone, 
				intercompany_flag, company_code, cms_flag, process_group_num, nat_cur_code, rate_type_home, rate_type_oper, 
				rate_home, rate_oper, net_original_amt, org_id, tax_freight_no_recoverable
			 FROM	apinpchg_all ')
		
		EXEC (' CREATE VIEW apinppyt
			AS
			SELECT timestamp, trx_ctrl_num, trx_type, doc_ctrl_num, trx_desc, batch_code, cash_acct_code, 
				date_entered, date_applied, date_doc, vendor_code, pay_to_code, approval_code, payment_code, 
				payment_type, amt_payment, amt_on_acct, posted_flag, printed_flag, hold_flag, approval_flag, 
				gen_id, user_id, void_type, amt_disc_taken, print_batch_num, company_code, process_group_num,
				nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper, payee_name, settlement_ctrl_num, 
				doc_amount, org_id 
			FROM apinppyt_all ')

		EXEC (' CREATE VIEW apinpstl
			AS
			SELECT timestamp, settlement_ctrl_num, vendor_code, pay_to_code, hold_flag, date_entered, date_applied, user_id, batch_code, 
			process_group_num, state_flag, disc_total_home, disc_total_oper, debit_memo_total_home, debit_memo_total_oper, on_acct_pay_total_home, 
			on_acct_pay_total_oper, payments_total_home,payments_total_oper, put_on_acct_total_home, put_on_acct_total_oper, gain_total_home, 
			gain_total_oper, loss_total_home, loss_total_oper, description,nat_cur_code, doc_count_expected, doc_count_entered, doc_sum_expected, 
			doc_sum_entered, vo_total_home, vo_total_oper, rate_type_home, rate_home,rate_type_oper, rate_oper, vo_amt_nat, amt_doc_nat, amt_dist_nat, 
			amt_on_acct, org_id
			FROM apinpstl_all ')
		
		EXEC (' CREATE VIEW appahdr
			AS
			SELECT timestamp, trx_ctrl_num, doc_ctrl_num, batch_code, date_posted, 
			      date_applied, date_entered, cash_acct_code, state_flag, void_flag,
			      doc_desc, user_id, journal_ctrl_num, process_ctrl_num, org_id
			FROM appahdr_all ')
		
		EXEC ('CREATE VIEW appyhdr
			AS
			SELECT timestamp, trx_ctrl_num, doc_ctrl_num, batch_code, date_posted, date_applied, date_doc, 
				date_entered, vendor_code, pay_to_code, approval_code, cash_acct_code, payment_code, state_flag, void_flag, 
				amt_net, amt_discount, amt_on_acct, payment_type, doc_desc, user_id, journal_ctrl_num, print_batch_num, 
				process_ctrl_num, currency_code, rate_type_home, rate_type_oper, rate_home, rate_oper, payee_name, 
				settlement_ctrl_num, org_id 
			FROM appyhdr_all ')
		
		EXEC (' CREATE VIEW appystl
			AS
			 SELECT timestamp, settlement_ctrl_num, vendor_code , pay_to_code, date_entered, date_applied, user_id, batch_code, process_group_num, 
			state_flag, disc_total_home, disc_total_oper, debit_memo_total_home, debit_memo_total_oper, on_acct_pay_total_home, on_acct_pay_total_oper, 
			payments_total_home, payments_total_oper, put_on_acct_total_home, put_on_acct_total_oper, gain_total_home, gain_total_oper, loss_total_home, 
			loss_total_oper, org_id
			  FROM appystl_all ')
		
		EXEC (' CREATE VIEW apvahdr
			AS
			SELECT timestamp, trx_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, vend_order_num, ticket_num, 
			date_posted, date_applied, date_aging, date_due, date_doc, date_entered, date_received, date_required, date_discount, fob_code, terms_code, 
			state_flag, doc_desc, user_id, journal_ctrl_num, process_ctrl_num, org_id
			FROM apvahdr_all ')
		
		EXEC (' CREATE VIEW apvohdr
			AS
			 SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num,
				 vend_order_num, ticket_num, date_posted, date_applied, date_aging, date_due, date_doc, date_entered,
				 date_received, date_required, date_paid, date_discount, posting_code, vendor_code, pay_to_code,
				 branch_code, class_code, approval_code, comment_code, fob_code, terms_code, tax_code, recurring_code, 
				 payment_code, state_flag, paid_flag, recurring_flag, one_time_vend_flag, one_check_flag, accrual_flag, 
				 times_accrued, amt_gross, amt_discount, amt_freight, amt_tax, amt_misc, amt_net, amt_paid_to_date, 
				 amt_tax_included, frt_calc_tax, doc_desc, user_id, journal_ctrl_num, payment_hold_flag, intercompany_flag, 
				 process_ctrl_num, currency_code, rate_type_home, rate_type_oper, rate_home, rate_oper, net_original_amt, org_id,
				 tax_freight_no_recoverable 
			 FROM apvohdr_all ')

		EXEC ('CREATE VIEW apmaster
				AS
				SELECT timestamp, vendor_code, pay_to_code, address_name, short_name, 
					addr1, addr2, addr3, addr4, addr5, addr6, addr_sort1, addr_sort2, addr_sort3, 
					address_type, status_type, attention_name, attention_phone, contact_name, contact_phone, 
					tlx_twx, phone_1, phone_2, tax_code, terms_code, fob_code, posting_code, location_code, 
					orig_zone_code, customer_code, affiliated_vend_code, alt_vendor_code, comment_code, vend_class_code,
					branch_code, pay_to_hist_flag, item_hist_flag, credit_limit_flag, credit_limit, aging_limit_flag, 
					aging_limit, restock_chg_flag, restock_chg, prc_flag, vend_acct, tax_id_num, flag_1099, exp_acct_code,
					amt_max_check, lead_time, doc_ctrl_num, one_check_flag, dup_voucher_flag, dup_amt_flag, code_1099, 
					user_trx_type_code, payment_code, limit_by_home, rate_type_home, rate_type_oper, nat_cur_code, one_cur_vendor,
					cash_acct_code, city, state, postal_code, country, freight_code, url, note, country_code, ftp, attention_email, 
					contact_email, etransmit_ind, vo_hold_flag, po_item_flag, buying_cycle, proc_vend_flag, extended_name, check_extendedname_flag 
				FROM apmaster_all ')

		IF EXISTS (SELECT name FROM sysobjects WHERE name = 'atmtchdr_all') 
			EXEC (' CREATE VIEW atmtchdr
				AS
				SELECT 	timestamp, 	invoice_no, 	vendor_code, 	amt_net, 	date_doc, 
				date_discount, 	nat_cur_code, 	status, 	date_posted, 	date_imported, 
				num_failed, 	date_failed, 	source_module, 	error_desc, 	amt_tax, 	
				amt_discount, 	amt_freight, 	amt_misc, 	org_id 
				FROM atmtchdr_all
			     ')   

		IF EXISTS (SELECT name FROM sysobjects WHERE name = 'epmchhdr_all') 
			EXEC (' CREATE VIEW epmchhdr
				AS
				SELECT  timestamp, 	match_ctrl_num, 	vendor_code, 		vendor_remit_to, 
					vendor_invoice_no, date_match, 		tolerance_hold_flag, 	tolerance_approval_flag, 
					validated_flag, vendor_invoice_date, 	invoice_receive_date, 	apply_date, 
					aging_date, 	due_date, 		discount_date, 		amt_net, 
					amt_discount, 	amt_tax, 		amt_freight, 		amt_misc, 
					amt_due, 	match_posted_flag, 	amt_tax_included, 	trx_ctrl_num, 	
					nat_cur_code, 	rate_type_home, 	rate_type_oper, 	rate_home, 
					rate_oper, 	batch_code, 		org_id 
				FROM  epmchhdr_all
			      ') 
				
	END


	EXEC ( 'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apdmhdr TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apinpchg TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apinppyt TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apinpstl TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON appahdr TO PUBLIC  
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON appyhdr TO PUBLIC     
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON appystl TO PUBLIC         
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apvahdr TO PUBLIC         
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apvohdr TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON apmaster TO PUBLIC


		')   
		
		
		
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'atmtchdr_all')	
	   EXEC ( 'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON atmtchdr TO PUBLIC')
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'epmchhdr_all') 
	   EXEC ( 'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON epmchhdr TO PUBLIC')   
GO
GRANT EXECUTE ON  [dbo].[ap_rebuildviews_sp] TO [public]
GO
