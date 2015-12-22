SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[ammasast_vw] 
AS 

SELECT 
 	ma.timestamp,
 	ma.mass_maintenance_id,
 	ma.company_id,
 	ma.asset_ctrl_num,
 	a.asset_description,
 	a.activity_state,
 	comment = ma.error_message,
		a.co_asset_id,
	a.org_id
FROM 	ammasast ma,
 	amasset a 
WHERE 	ma.company_id 		= a.company_id
AND		ma.asset_ctrl_num	= a.asset_ctrl_num 

GO
GRANT REFERENCES ON  [dbo].[ammasast_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ammasast_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ammasast_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ammasast_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ammasast_vw] TO [public]
GO
