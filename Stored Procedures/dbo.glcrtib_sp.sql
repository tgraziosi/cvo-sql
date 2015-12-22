SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                


























                                                  

CREATE PROCEDURE [dbo].[glcrtib_sp]
AS

	EXEC InterBranchAccts_reg_sp
	EXEC sm_account_vs_org_reg_sp
	EXEC sm_accounts_access_co_sec_reg_sp 
	EXEC sm_accounts_access_sec_reg_sp 
	EXEC sm_customer_vs_org_reg_sp 
	EXEC sm_customers_access_co_reg_sp 
	EXEC sm_customers_access_reg_sp 
	EXEC sm_vendor_vs_org_reg_sp
	EXEC sm_vendors_access_co_reg_sp 
	EXEC sm_vendors_access_reg_sp
	EXEC batchctl_reg_sp
	
	EXEC sm_get_current_org_reg_sp
	EXEC sm_login_reg_sp
	EXEC sm_logoff_reg_sp

	IF EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 2000 )	--AR
		EXEC ar_rebuildviews_sp
	
	IF EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 4000 )	--AP
		EXEC ap_rebuildviews_sp
	
	IF EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 6000 )	--GL
		EXEC gl_rebuildviews_sp
	
	IF EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 7000 )	--CM
		EXEC cm_rebuildviews_sp

	IF EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 10000 )	--AM
		EXEC am_glchart_root_reg_sp

	IF EXISTS ( SELECT 1 FROM CVO_Control..s2papprg WHERE company_db_name = db_name() AND app_id = 18000 )	--ADM
		EXEC adm_rebuildviews_sp
                                              
GO
GRANT EXECUTE ON  [dbo].[glcrtib_sp] TO [public]
GO
