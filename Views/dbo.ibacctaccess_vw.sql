SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                



























CREATE VIEW [dbo].[ibacctaccess_vw]
AS	
	SELECT 
		a.organization_id,
		a.account_code,
		account_description,
		account_type,
		account_type_description,
		date_active,
		date_inactive,
		inactive_flag,
		consol_type,
		consol_flag,
		currency_code,
		revaluate_flag,
		rate_type_home,
		rate_type_oper,
		x_date_active,
		x_date_inactive 
	FROM
		sm_account_access_co_2_vw a INNER JOIN glchrPE_vw g ON a.account_code = g.account_code AND a.organization_id = g.org_id
GO
GRANT REFERENCES ON  [dbo].[ibacctaccess_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibacctaccess_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibacctaccess_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibacctaccess_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibacctaccess_vw] TO [public]
GO
