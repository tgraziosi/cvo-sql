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


CREATE VIEW [dbo].[oodef_vw] AS
SELECT * FROM  OrganizationOrganizationDef


GO
GRANT REFERENCES ON  [dbo].[oodef_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[oodef_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[oodef_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[oodef_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[oodef_vw] TO [public]
GO
