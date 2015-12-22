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

CREATE VIEW [dbo].[smmyglobalvendors_vw]
AS 		
		SELECT DISTINCT   vendor_mask
		FROM smvendorgrpdet d,securitytokendetail o, smvendorgrphdr h
			WHERE
 			   h.group_id = d.group_id
			   AND h.global_flag = 1

GO
GRANT REFERENCES ON  [dbo].[smmyglobalvendors_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smmyglobalvendors_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smmyglobalvendors_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smmyglobalvendors_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmyglobalvendors_vw] TO [public]
GO
