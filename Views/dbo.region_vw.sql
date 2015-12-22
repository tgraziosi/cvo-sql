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
























CREATE VIEW [dbo].[region_vw]
AS
SELECT region_id, org_id, parent_outline_num, parent_region_flag
FROM IBregion_all, Organization 
WHERE Organization.organization_id = IBregion_all.org_id


GO
GRANT REFERENCES ON  [dbo].[region_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[region_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[region_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[region_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[region_vw] TO [public]
GO
