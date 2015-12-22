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

CREATE VIEW [dbo].[glchart_root_access_vw]
AS
	SELECT account_code, account_description, inactive_flag
	FROM glchart_root_vw 
	WHERE account_code IN 
		(SELECT account_code 
		 FROM sm_accounts_access_vw)
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glchart_root_access_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glchart_root_access_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart_root_access_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glchart_root_access_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart_root_access_vw] TO [public]
GO
