SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[amastcls_vw] 

AS 

SELECT 	ac.timestamp timestamp,
 	ac.company_id,
 	ac.classification_id,
 	ac.co_asset_id,
 	ac.classification_code,
 	c.classification_description, 
 	ac.last_modified_date,
 	ac.modified_by
FROM 	amastcls ac,
 	amcls c 
WHERE 	ac.company_id 			= c.company_id
AND		ac.classification_id 	= c.classification_id
AND		ac.classification_code 	= c.classification_code

GO
GRANT REFERENCES ON  [dbo].[amastcls_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amastcls_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amastcls_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amastcls_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastcls_vw] TO [public]
GO
