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

CREATE VIEW [dbo].[smmyorgsbymytokens_vw] 
AS 
	SELECT myt.security_token, organization_id org_id  
	FROM sm_my_tokens myt, organizationsecurity org
	WHERE myt.security_token = org.security_token 
GO
GRANT REFERENCES ON  [dbo].[smmyorgsbymytokens_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smmyorgsbymytokens_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smmyorgsbymytokens_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smmyorgsbymytokens_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmyorgsbymytokens_vw] TO [public]
GO
