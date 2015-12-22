SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[am_accounts_access_root_org_vw]
AS


SELECT  a.*
FROM	am_glchart_root_vw a, sm_accounts_access b
WHERE	inactive_flag  = 0
AND 	a.account_code = b.account_code 

GO
GRANT REFERENCES ON  [dbo].[am_accounts_access_root_org_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[am_accounts_access_root_org_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[am_accounts_access_root_org_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[am_accounts_access_root_org_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[am_accounts_access_root_org_vw] TO [public]
GO
