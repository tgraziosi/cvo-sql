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

























CREATE VIEW [dbo].[am_accounts_access_vw]
AS


SELECT  timestamp, account_code, account_description, account_type, new_flag, seg1_code, seg2_code, seg3_code, seg4_code, 
	consol_detail_flag, consol_type, active_date, inactive_date, inactive_flag, currency_code, revaluate_flag, rate_type_home, 
	rate_type_oper
FROM	glchart_vw
WHERE	inactive_flag  = 0
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[am_accounts_access_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[am_accounts_access_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[am_accounts_access_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[am_accounts_access_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[am_accounts_access_vw] TO [public]
GO
