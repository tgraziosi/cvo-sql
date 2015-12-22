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


CREATE VIEW [dbo].[ootrx_vw] AS
SELECT * FROM  OrganizationOrganizationTrx


GO
GRANT REFERENCES ON  [dbo].[ootrx_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ootrx_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ootrx_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ootrx_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ootrx_vw] TO [public]
GO
