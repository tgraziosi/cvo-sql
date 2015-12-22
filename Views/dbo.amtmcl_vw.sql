SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[amtmcl_vw] 

AS 

SELECT 	tc.timestamp timestamp,
 	tc.company_id,
 	tc.classification_id,
 	tc.template_code,
 	tc.classification_code,
 	c.classification_description, 
 	tc.last_modified_date,
 	tc.modified_by
FROM 	amtmplcl 	tc,
 	amcls 		c 
WHERE 	tc.company_id 			= c.company_id
AND		tc.classification_id 	= c.classification_id
AND		tc.classification_code 	= c.classification_code

GO
GRANT REFERENCES ON  [dbo].[amtmcl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amtmcl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amtmcl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amtmcl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtmcl_vw] TO [public]
GO
