SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ampurge_vwFirstFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id						smCompanyID,
	@asset_ctrl_num_filter			varchar(16)
) 
AS 

SET ROWCOUNT @rowsrequested 

SELECT 
	 timestamp, company_id, date_purged=CONVERT(char(8), date_created, 112), time_purged=CONVERT(varchar(20), date_created, 114), co_asset_id, asset_ctrl_num, asset_description, activity_state, mass_maintenance_id, mass_description, comment, user_name, date_acquisition=CONVERT(char(8), acquisition_date, 112), date_disposition=CONVERT(char(8), disposition_date, 112), original_cost, lp_fiscal_period_end=CONVERT(char(8), lp_fiscal_period_end, 112), lp_accum_depr=-lp_accum_depr, lp_current_cost, updated_by 
FROM 	ampurge_vw 
WHERE 	asset_ctrl_num 		LIKE RTRIM(@asset_ctrl_num_filter)
ORDER BY asset_ctrl_num, date_created 

SET ROWCOUNT 0

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwFirstFilt_sp] TO [public]
GO
