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




create view [dbo].[arloc_vw] as

SELECT  location,
 	name,
	location AS alt_location,
	name AS alt_location_name
FROM    
	locations

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arloc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arloc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arloc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arloc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arloc_vw] TO [public]
GO
