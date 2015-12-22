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

CREATE VIEW [dbo].[amasttyp_vw]
AS 
select classification_id+1000 as 'field_id',  classification_name as 'field_name' from amclshdr
UNION
Select'1','Location'
UNION
Select'2','Employee'
UNION
Select'3','AssetType'
UNION
Select'4','StatusCode'
UNION
Select'5','Category'
UNION
Select'6','State'
UNION
Select'7','Asset Control Number'
UNION
Select'9','Asset Quantity'
UNION
Select'51','Usage Business'
UNION
Select'52','Usage Personal'
UNION
Select'53','Usage Investment'
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amasttyp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amasttyp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amasttyp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amasttyp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amasttyp_vw] TO [public]
GO
