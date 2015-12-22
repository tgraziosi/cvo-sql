SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampurge_vwLastFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id						smCompanyID,
	@asset_ctrl_num_filter			varchar(16)
) 
as 

CREATE TABLE #temp ( timestamp varbinary(8) NULL, company_id smallint NULL, date_created datetime NULL, co_asset_id int NULL, asset_ctrl_num varchar(16) NULL, asset_description varchar(40) NULL, activity_state tinyint, mass_maintenance_id int, mass_description varchar(16) NULL, comment varchar(255) NULL, user_name varchar(16) NULL, acquisition_date datetime NULL, disposition_date datetime NULL, original_cost float NULL, lp_fiscal_period_end datetime NULL, lp_accum_depr float NULL, lp_current_cost float NULL, updated_by smallint )
declare @rowsfound 	smallint 
declare @MSKasset 	varchar(16)
declare @MSKdt		datetime 

select @rowsfound = 0 


set rowcount 1
select 	@MSKasset 			= max(asset_ctrl_num) 
from 	ampurge_vw 
where 	asset_ctrl_num 		like RTRIM(@asset_ctrl_num_filter)
AND 	company_id			= @company_id
set rowcount 0

if 	@MSKasset is null 
begin 
 drop table #temp 
 return 
end 


while @MSKasset is not null and @rowsfound < @rowsrequested 
begin 

	 
	select 	@MSKdt				= max(date_created)
	FROM 	ampurge_vw
	where 	asset_ctrl_num 		= @MSKasset 
	AND 	company_id			= @company_id

	
	while @MSKdt is not null and @rowsfound < @rowsrequested 
	begin 

		insert 	into #temp 
		select 	 
				timestamp,
				company_id, date_created, co_asset_id , asset_ctrl_num, asset_description, activity_state, mass_maintenance_id, mass_description, comment , user_name, acquisition_date, disposition_date, original_cost, lp_fiscal_period_end, lp_accum_depr , lp_current_cost, updated_by
		from 	ampurge_vw 
		where 	date_created 			= @MSKdt
		

		select @rowsfound = @rowsfound + @@rowcount 


			
		select 	@MSKdt		= max(date_created) 
		from 	ampurge_vw 
		where 	asset_ctrl_num 		= @MSKasset 
		AND 	company_id			= @company_id
		AND		date_created		< @MSKdt

	END

	SET ROWCOUNT 1
	select 	@MSKasset 	= max(asset_ctrl_num) 
	from 	ampurge_vw 
	where 	asset_ctrl_num 		like RTRIM(@asset_ctrl_num_filter)
	AND 	company_id			= @company_id
	AND		asset_ctrl_num		< @MSKasset 
	SET ROWCOUNT 0
 end 

select 
	timestamp, company_id, date_purged=CONVERT(char(8), date_created, 112), time_purged=CONVERT(varchar(20), date_created, 114), co_asset_id, asset_ctrl_num, asset_description, activity_state, mass_maintenance_id, mass_description, comment, user_name, date_acquisition=CONVERT(char(8), acquisition_date, 112), date_disposition=CONVERT(char(8), disposition_date, 112), original_cost, lp_fiscal_period_end=CONVERT(char(8), lp_fiscal_period_end, 112), lp_accum_depr=-lp_accum_depr, lp_current_cost, updated_by
from #temp 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwLastFilt_sp] TO [public]
GO
