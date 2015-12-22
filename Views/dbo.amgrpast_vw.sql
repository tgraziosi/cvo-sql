SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 
CREATE VIEW [dbo].[amgrpast_vw] 
AS 

SELECT 
 	ga.timestamp,
		ga.modified_by,
 	ga.group_id,
 	ga.company_id,
 	ga.asset_ctrl_num,
 	a.asset_description 
FROM 	amgrpast ga,
 	amasset a 
WHERE 	ga.company_id		= a.company_id 
AND		ga.asset_ctrl_num = a.asset_ctrl_num

GO
GRANT REFERENCES ON  [dbo].[amgrpast_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amgrpast_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amgrpast_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amgrpast_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amgrpast_vw] TO [public]
GO
