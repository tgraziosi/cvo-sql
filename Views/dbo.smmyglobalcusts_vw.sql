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

CREATE VIEW [dbo].[smmyglobalcusts_vw] 
AS 
		SELECT DISTINCT   customer_mask
		FROM smcustomergrpdet d,securitytokendetail o, smcustomergrphdr h
			WHERE
 			   h.group_id = d.group_id
			   AND h.global_flag = 1

GO
GRANT REFERENCES ON  [dbo].[smmyglobalcusts_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smmyglobalcusts_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smmyglobalcusts_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smmyglobalcusts_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmyglobalcusts_vw] TO [public]
GO
