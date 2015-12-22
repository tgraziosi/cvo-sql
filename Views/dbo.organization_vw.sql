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






CREATE VIEW [dbo].[organization_vw] AS
SELECT organization_id	org_id,	organization_name organizationname, *
FROM  Organization
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[organization_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[organization_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[organization_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[organization_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[organization_vw] TO [public]
GO
