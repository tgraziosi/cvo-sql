SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[cm_rebuildviews_sp]
AS

IF NOT EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 7000 )	--CM
	return 0

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'cmtrxbtr' AND type = 'V') 
		DROP VIEW cmtrxbtr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'cmtrx' AND type = 'V') 
		DROP VIEW cmtrx
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'cmmanhdr' AND type = 'V') 
		DROP VIEW cmmanhdr
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'cminpbtr' AND type = 'V') 
		DROP VIEW cminpbtr

IF (( EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1)))
	BEGIN
		EXEC(' CREATE VIEW cmtrxbtr
			AS
			  SELECT  timestamp, trx_ctrl_num, trx_type, description, doc_ctrl_num, date_applied, date_document, 
				date_entered, date_posted, cash_acct_code_from, cash_acct_code_to, acct_code_trans_from, 
				acct_code_trans_to, acct_code_clr, currency_code_from, currency_code_to, curr_code_trans_from, 
				curr_code_trans_to, trx_type_cls_from, trx_type_cls_to, amount_from, amount_to, bank_charge_amt_from, 
				bank_charge_amt_to, batch_code, gl_trx_id, user_id, auto_rec_flag, to_reference_code, to_expense_account_code, 
				to_expense_reference_code, from_reference_code, from_expense_account_code, from_expense_reference_code, 
				from_org_id, to_org_id 
			  FROM cmtrxbtr_all
				WHERE dbo.sm_organization_access_fn(from_org_id) =1
					AND dbo.sm_organization_access_fn(to_org_id) =1 ')

		EXEC(' CREATE VIEW cmtrx
			AS
			  SELECT  timestamp, trx_ctrl_num, trx_type, batch_code, cash_acct_code, user_id, gl_trx_id, date_posted, 
				date_applied, date_entered, reference_code, org_id 
			  FROM cmtrx_all
				WHERE dbo.sm_organization_access_fn(org_id) =1 ')

		EXEC(' CREATE VIEW cmmanhdr
			AS
			  SELECT timestamp, trx_ctrl_num, trx_type, description, batch_code, cash_acct_code, user_id, date_applied, 
				date_entered, hold_flag, posted_flag, total, currency_code, rate_type_home, rate_type_oper, rate_home, 
				rate_oper, process_group_num, reference_code, org_id, interbranch_flag, temp_flag 
			  FROM cmmanhdr_all
				WHERE dbo.sm_organization_access_fn(org_id) =1
				 	AND dbo.sm_access_to_cmmandtl_fn(trx_ctrl_num , trx_type ) =1 ')

		EXEC(' CREATE VIEW cminpbtr
			AS
			  SELECT timestamp, trx_ctrl_num, description, doc_ctrl_num, date_applied, date_document, date_entered, 
				cash_acct_code_from, cash_acct_code_to, currency_code_from, currency_code_to, amount_from, amount_to, 
				bank_charge_amt_from, bank_charge_amt_to, trx_type_cls_from, trx_type_cls_to, exchange_rate, hold_flag, 
				prc_gl_flag, posted_flag, user_id, batch_code, process_group_num, to_reference_code, to_expense_account_code, 
				to_expense_reference_code, from_reference_code, from_expense_account_code, from_expense_reference_code, 
				from_org_id, to_org_id 
			  FROM cminpbtr_all		 
				WHERE dbo.sm_organization_access_fn(from_org_id) =1
					AND dbo.sm_organization_access_fn(to_org_id) =1 ')
	END
ELSE
	BEGIN
		EXEC(' CREATE VIEW cmtrxbtr
			AS
			  SELECT  timestamp, trx_ctrl_num, trx_type, description, doc_ctrl_num, date_applied, date_document, 
				date_entered, date_posted, cash_acct_code_from, cash_acct_code_to, acct_code_trans_from, 
				acct_code_trans_to, acct_code_clr, currency_code_from, currency_code_to, curr_code_trans_from, 
				curr_code_trans_to, trx_type_cls_from, trx_type_cls_to, amount_from, amount_to, bank_charge_amt_from, 
				bank_charge_amt_to, batch_code, gl_trx_id, user_id, auto_rec_flag, to_reference_code, to_expense_account_code, 
				to_expense_reference_code, from_reference_code, from_expense_account_code, from_expense_reference_code, 
				from_org_id, to_org_id 
			  FROM cmtrxbtr_all ')

		EXEC(' CREATE VIEW cmtrx
			AS
			  SELECT  timestamp, trx_ctrl_num, trx_type, batch_code, cash_acct_code, user_id, gl_trx_id, date_posted, 
				date_applied, date_entered, reference_code, org_id 
			  FROM cmtrx_all ')

		EXEC(' CREATE VIEW cmmanhdr
			AS
			  SELECT timestamp, trx_ctrl_num, trx_type, description, batch_code, cash_acct_code, user_id, date_applied, 
				date_entered, hold_flag, posted_flag, total, currency_code, rate_type_home, rate_type_oper, rate_home, 
				rate_oper, process_group_num, reference_code, org_id, interbranch_flag, temp_flag 
			  FROM cmmanhdr_all ')

		EXEC(' CREATE VIEW cminpbtr
			AS
			  SELECT timestamp, trx_ctrl_num, description, doc_ctrl_num, date_applied, date_document, date_entered, 
				cash_acct_code_from, cash_acct_code_to, currency_code_from, currency_code_to, amount_from, amount_to, 
				bank_charge_amt_from, bank_charge_amt_to, trx_type_cls_from, trx_type_cls_to, exchange_rate, hold_flag, 
				prc_gl_flag, posted_flag, user_id, batch_code, process_group_num, to_reference_code, to_expense_account_code, 
				to_expense_reference_code, from_reference_code, from_expense_account_code, from_expense_reference_code, 
				from_org_id, to_org_id 
			  FROM cminpbtr_all ')
	END


	EXEC ( 'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON cmtrxbtr TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON cmtrx TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON cmmanhdr TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON cminpbtr TO PUBLIC')   
GO
GRANT EXECUTE ON  [dbo].[cm_rebuildviews_sp] TO [public]
GO
