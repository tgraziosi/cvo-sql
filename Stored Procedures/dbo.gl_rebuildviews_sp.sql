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

CREATE PROCEDURE [dbo].[gl_rebuildviews_sp]
AS

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'gltrx' AND type = 'V') 
		DROP VIEW gltrx
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'glrecur' AND type = 'V') 
		DROP VIEW glrecur
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'glreall' AND type = 'V') 
		DROP VIEW glreall
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'Organization' AND type = 'V') 
		DROP VIEW Organization

-- add ibifc, ibhdr

        IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_organization_access_fn' ) 
		DROP FUNCTION sm_organization_access_fn 
		
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'ibifc' AND type = 'V') 
	        DROP VIEW ibifc
	
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'ibhdr' AND type = 'V') 
	        DROP VIEW ibhdr
        
		

IF (( EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1)))
	BEGIN
		
               EXEC (' CREATE FUNCTION sm_organization_access_fn ( @org_id varchar(30)) 
		 RETURNS smallint 
		  BEGIN   
		  DECLARE @ret SMALLINT 
		  SELECT @ret = count (access) 
		  FROM ( 
			SELECT DISTINCT 1 access 
		       FROM organizationsecurity org, sm_my_tokens myt 
		       WHERE 
			 myt.security_token = org.security_token 
		     AND org.organization_id = @org_id 
		     AND ( dbo.sm_ext_security_is_installed_fn() =1 
		      OR dbo.sm_user_is_administrator_fn()=0) 
		      UNION SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn() =0 
		      OR dbo.sm_user_is_administrator_fn()=1 
		      ) a 
		     RETURN @ret 
		END ') 		

                GRANT EXEC ON sm_organization_access_fn TO PUBLIC 		

                EXEC(' CREATE VIEW Organization
			AS
			SELECT 	timestamp, organization_id, organization_name, active_flag, outline_num, branch_account_number, 
				new_flag, create_date, create_username, last_change_date, last_change_username, 
				addr1, addr2, addr3, addr4, addr5, addr6, city, state, postal_code, country, tax_id_num, 
				region_flag, inherit_security, inherit_setup, tc_companycode
			FROM Organization_all
			WHERE (
		
				EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
				OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
				OR
				organization_id in ( SELECT org_id from smmyorgsbymytokens_vw )
			 )')
				
		EXEC(' CREATE VIEW gltrx
			AS
			SELECT timestamp, journal_type, journal_ctrl_num, journal_description, date_entered, date_applied,
				recurring_flag, repeating_flag, reversing_flag, hold_flag, posted_flag, date_posted, source_batch_code, 
				batch_code, type_flag, intercompany_flag, company_code, app_id, home_cur_code, document_1, trx_type, 
				user_id, source_company_code, process_group_num, oper_cur_code, org_id, interbranch_flag 
			FROM gltrx_all
			WHERE exists (select 1 from org_org_vw where organization_id = gltrx_all.org_id) and
			( posted_flag = 1 OR (
					EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )  OR
					EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR
					not exists (select 1 from gltrxdet d 
					inner join glco c on ( d.rec_company_code = c.company_code )
					where gltrx_all.journal_ctrl_num = d.journal_ctrl_num 
					AND interbranch_flag = 1
					AND not exists (select 1 from org_org_vw where org_id = organization_id) ))
			 )  ')

		
		EXEC(' CREATE VIEW glrecur
			AS
			SELECT timestamp, journal_ctrl_num, recur_description, journal_type, tracked_balance_flag, percentage_flag, 
				continuous_flag, year_end_type, recur_if_zero_flag, hold_flag, posted_flag, tracked_balance_amount, 
				base_amount, date_last_applied, date_end_period_1, date_end_period_2, date_end_period_3, date_end_period_4, 
				date_end_period_5, date_end_period_6, date_end_period_7, date_end_period_8, date_end_period_9, 
				date_end_period_10, date_end_period_11, date_end_period_12, date_end_period_13, all_periods, 
				number_of_periods, period_interval, intercompany_flag, nat_cur_code, document_1, rate_type_home, 
				rate_type_oper, org_id, interbranch_flag 
			FROM glrecur_all
			 WHERE 	exists (select 1 from org_org_vw where organization_id = glrecur_all.org_id) and
				(	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )  OR
					EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR
		  			not exists (select 1 from glrecdet d 
					inner join glco c on ( d.rec_company_code = c.company_code )
					where glrecur_all.journal_ctrl_num = d.journal_ctrl_num 
					and not exists (select 1 from org_org_vw where org_id = organization_id)) 
				) ')

		EXEC(' CREATE VIEW glreall
			AS
			SELECT g.timestamp, g.journal_ctrl_num, g.journal_type, g.journal_description, g.date_entered, g.date_posted, g.date_last_applied, 
				g.batch_code, g.hold_flag, g.posted_flag, g.based_type, g.budget_code, g.nonfin_budget_code, g.account_code, g.intercompany_flag, 
				g.org_id, g.interbranch_flag 
			FROM glreall_all g
			WHERE 	EXISTS( SELECT 1 FROM Organization WHERE organization_id = org_id )
			AND exists( select 1 from sm_account_masks_by_org_vw s 
				where g.account_code like s.account_mask 
				AND (s.organization_id = g.org_id OR s.global_flag = 1)) AND
				(	
					EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )  OR
					EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR
					not exists (select 1 from glreadet d 
						inner join glco c on ( d.rec_company_code = c.company_code )
						where d.journal_ctrl_num = g.journal_ctrl_num  
						and not exists (select 1 from org_org_vw where org_id = organization_id) )
				) ')

			 
	        EXEC (' CREATE VIEW ibifc
	                 AS
	                 SELECT timestamp, id, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id, amount, 
		                currency_code, tax_code, recipient_code, originator_code, tax_payable_code, tax_expense_code, 
		                state_flag, process_ctrl_num, link1, link2, link3, username, reference_code, hold_flag, hold_desc 
	                 FROM ibifc_all
		         WHERE 	(EXISTS( SELECT 1 FROM Organization WHERE organization_id = controlling_org_id ) 
		         OR LEN( controlling_org_id) =0)
	               ')
	               
	        EXEC (' CREATE VIEW ibhdr
		 	AS
		 	SELECT 	timestamp, id, trx_ctrl_num, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id,
		 	 	amount, currency_code, tax_code, doc_description, create_date, create_username, last_change_date, 
		 		last_change_username 
		 	FROM ibhdr_all
			WHERE 	EXISTS ( select 1 from Organization where organization_id = controlling_org_id ) 
			AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )  OR
					EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) OR
					NOT EXISTS (select 1 from ibdet d 
						where d.id = ibhdr_all.id
						and not exists (select 1 from org_org_vw where org_id = organization_id) ))
				 ')
	        
	END
ELSE
	BEGIN

		EXEC('	CREATE FUNCTION sm_organization_access_fn ( @org_id varchar(30)) 
			 RETURNS smallint 
			BEGIN   
			     RETURN 1 
			END')

                GRANT EXEC ON sm_organization_access_fn TO PUBLIC 

		EXEC(' CREATE VIEW Organization
			AS
			SELECT 	timestamp, organization_id, organization_name, active_flag, outline_num, branch_account_number, 
				new_flag, create_date, create_username, last_change_date, last_change_username, 
				addr1, addr2, addr3, addr4, addr5, addr6, city, state, postal_code, country, tax_id_num, 
				region_flag, inherit_security, inherit_setup, tc_companycode 
			FROM Organization_all')
				
		EXEC(' CREATE VIEW gltrx
			AS
			SELECT timestamp, journal_type, journal_ctrl_num, journal_description, date_entered, date_applied,
				recurring_flag, repeating_flag, reversing_flag, hold_flag, posted_flag, date_posted, source_batch_code, 
				batch_code, type_flag, intercompany_flag, company_code, app_id, home_cur_code, document_1, trx_type, 
				user_id, source_company_code, process_group_num, oper_cur_code, org_id, interbranch_flag 
			FROM gltrx_all ')
		
		EXEC(' CREATE VIEW glrecur
			AS
			SELECT timestamp, journal_ctrl_num, recur_description, journal_type, tracked_balance_flag, percentage_flag, 
				continuous_flag, year_end_type, recur_if_zero_flag, hold_flag, posted_flag, tracked_balance_amount, 
				base_amount, date_last_applied, date_end_period_1, date_end_period_2, date_end_period_3, date_end_period_4, 
				date_end_period_5, date_end_period_6, date_end_period_7, date_end_period_8, date_end_period_9, 
				date_end_period_10, date_end_period_11, date_end_period_12, date_end_period_13, all_periods, 
				number_of_periods, period_interval, intercompany_flag, nat_cur_code, document_1, rate_type_home, 
				rate_type_oper, org_id, interbranch_flag 
			FROM glrecur_all ')

			
		EXEC(' CREATE VIEW glreall
			AS
			SELECT timestamp, journal_ctrl_num, journal_type, journal_description, date_entered, date_posted, date_last_applied, 
				batch_code, hold_flag, posted_flag, based_type, budget_code, nonfin_budget_code, account_code, intercompany_flag, 
				org_id, interbranch_flag 
			FROM glreall_all ')			
			
                EXEC (' CREATE VIEW ibifc
	                 AS
	                 SELECT timestamp, id, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id, amount, 
		                currency_code, tax_code, recipient_code, originator_code, tax_payable_code, tax_expense_code, 
		                state_flag, process_ctrl_num, link1, link2, link3, username, reference_code, hold_flag, hold_desc 
	                 FROM ibifc_all
	               ')
	               
	        EXEC (' CREATE VIEW ibhdr
		 	AS
		 	SELECT 	timestamp, id, trx_ctrl_num, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id,
		 	 	amount, currency_code, tax_code, doc_description, create_date, create_username, last_change_date, 
		 		last_change_username 
		 	FROM ibhdr_all
	               ')	               
	               

			
	END


	EXEC ( ' GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON gltrx TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON glrecur TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON glreall TO PUBLIC
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON Organization TO PUBLIC 
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON ibifc TO PUBLIC 
		GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE  ON ibhdr TO PUBLIC
		' )  



	EXEC ib_glchart_reg_sp

	EXEC glchart_w_org_w_sec_reg_sp	

	
GO
GRANT EXECUTE ON  [dbo].[gl_rebuildviews_sp] TO [public]
GO
