SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

            
CREATE VIEW [dbo].[amOrganization_vw] AS
SELECT *
FROM  organization_vw
WHERE active_flag  =1 
AND new_flag = 0 
AND (region_flag =0  OR outline_num ='1')

GO
GRANT REFERENCES ON  [dbo].[amOrganization_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amOrganization_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amOrganization_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amOrganization_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amOrganization_vw] TO [public]
GO
