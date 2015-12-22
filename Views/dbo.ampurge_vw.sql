SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[ampurge_vw] 
AS 

SELECT 
       	pu.timestamp,
		pu.co_asset_id,
       	pu.company_id,
       	pu.asset_ctrl_num,
		pu.asset_description,
       	pu.activity_state,
		pu.mass_maintenance_id,
		ma.mass_description,
       	pu.comment,
		pu.date_created,
		s.user_name,
		pu.acquisition_date,
		pu.disposition_date,
		pu.original_cost,
		pu.lp_fiscal_period_end,
		pu.lp_accum_depr,
		pu.lp_current_cost,
		pu.updated_by
FROM   	ampurge pu LEFT OUTER JOIN ammashdr ma 	ON pu.mass_maintenance_id = ma.mass_maintenance_id
	LEFT OUTER JOIN CVO_Control..smusers s ON pu.created_by = s.user_id 







GO
GRANT REFERENCES ON  [dbo].[ampurge_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ampurge_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ampurge_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ampurge_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ampurge_vw] TO [public]
GO
