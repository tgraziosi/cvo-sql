SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampurge_vwNextRow_sp] 
( 
	@company_id smallint, @date_purged char(8), @time_purged varchar(20)
 
) as 


DECLARE @MSKdt	datetime
SELECT 	@MSKdt = @date_purged + " " + @time_purged

select 	@MSKdt = min(date_created) 
from 	ampurge_vw 
where 	date_created > @MSKdt
AND 	company_id	 = @company_id

select 
		timestamp, company_id, date_purged=CONVERT(char(8), date_created, 112), time_purged=CONVERT(varchar(20), date_created, 114), co_asset_id, asset_ctrl_num, asset_description, activity_state, mass_maintenance_id, mass_description, comment, user_name, date_acquisition=CONVERT(char(8), acquisition_date, 112), date_disposition=CONVERT(char(8), disposition_date, 112), original_cost, lp_fiscal_period_end=CONVERT(char(8), lp_fiscal_period_end, 112), lp_accum_depr=-lp_accum_depr, lp_current_cost, updated_by
from 	ampurge_vw 
where 	date_created = @MSKdt

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwNextRow_sp] TO [public]
GO
