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
CREATE VIEW [dbo].[amclassname_vw]
AS
SELECT
	hdr.classification_id,
	ast.classification_code,
	hdr.classification_name,
	ast.co_asset_id
FROM 	amclshdr hdr LEFT OUTER JOIN amastcls ast ON hdr.classification_id = ast.classification_id


GO
GRANT REFERENCES ON  [dbo].[amclassname_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amclassname_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amclassname_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amclassname_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amclassname_vw] TO [public]
GO
