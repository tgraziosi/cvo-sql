SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[apdmhdr_reg_sp]
AS

IF NOT EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 4000 )	--AP
	RETURN 0

DECLARE @buf varchar(8000)
DECLARE @buf2 varchar(8000)

IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = 'apdmhdr'  AND type = 'V') 
		DROP VIEW apdmhdr
				
SELECT @buf2 = 'CREATE  VIEW apdmhdr AS '

IF (EXISTS ( SELECT 1 FROM glco WHERE  ib_flag =0 ) AND ( EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=0)))
	BEGIN
		SELECT 'InterOrg turned off + security turned off'
			SELECT @buf =	' 
				SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, 
					vend_order_num, ticket_num, date_posted, date_applied, date_doc, date_entered, posting_code, vendor_code, 
					pay_to_code, branch_code, class_code, comment_code, fob_code, tax_code, state_flag, amt_gross, amt_discount, 
					amt_freight, amt_tax, amt_misc, amt_net, amt_restock, amt_tax_included, frt_calc_tax, doc_desc, user_id, 
					journal_ctrl_num, intercompany_flag, process_ctrl_num, currency_code, rate_type_home, rate_type_oper, 
					rate_home, rate_oper, org_id, tax_freight_no_recoverable 
				FROM apdmhdr_all '
	END
ELSE
	BEGIN
		SELECT @buf =	' 
			SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, 
				vend_order_num, ticket_num, date_posted, date_applied, date_doc, date_entered, posting_code, vendor_code, 
				pay_to_code, branch_code, class_code, comment_code, fob_code, tax_code, state_flag, amt_gross, amt_discount, 
				amt_freight, amt_tax, amt_misc, amt_net, amt_restock, amt_tax_included, frt_calc_tax, doc_desc, user_id, 
				journal_ctrl_num, intercompany_flag, process_ctrl_num, currency_code, rate_type_home, rate_type_oper, 
				rate_home, rate_oper, org_id, tax_freight_no_recoverable 
			FROM apdmhdr_all
			WHERE 	
				EXISTS( SELECT 1 FROM org_org_vw WHERE organization_id = org_id )
				AND (	EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
				OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() )
				OR EXISTS ( SELECT 1 FROM smmyvendorsbymyorgsbymytokens_vw
					WHERE vendor_code like vendor_mask AND  organization_id = org_id )
				OR EXISTS ( SELECT 1 FROM smmyglobalvendors_vw WHERE vendor_code like vendor_mask ) )'
	END	
							
EXEC ( @buf2 + @buf )
GRANT ALL ON apdmhdr TO PUBLIC     

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apdmhdr_reg_sp] TO [public]
GO
