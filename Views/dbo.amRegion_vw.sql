SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amRegion_vw] AS      
SELECT DISTINCT region_id FROM region_vw 
WHERE (parent_region_flag = 1 OR parent_outline_num = '1')
GO
GRANT REFERENCES ON  [dbo].[amRegion_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amRegion_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amRegion_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amRegion_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amRegion_vw] TO [public]
GO
