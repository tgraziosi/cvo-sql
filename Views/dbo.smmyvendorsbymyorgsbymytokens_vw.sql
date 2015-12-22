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

CREATE VIEW [dbo].[smmyvendorsbymyorgsbymytokens_vw]
AS 
		SELECT DISTINCT organization_id, vendor_mask
		FROM smvendorgrpdet d, securitytokendetail o,
		     organizationsecurity	org, sm_my_tokens	myt
			WHERE
			   d.group_id = o.group_id
			   AND o.type=  2
			   AND org.security_token = o.security_token
			   AND myt.security_token = org.security_token

GO
GRANT REFERENCES ON  [dbo].[smmyvendorsbymyorgsbymytokens_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smmyvendorsbymyorgsbymytokens_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smmyvendorsbymyorgsbymytokens_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smmyvendorsbymyorgsbymytokens_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmyvendorsbymyorgsbymytokens_vw] TO [public]
GO
