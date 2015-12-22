SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampurge_vwPrev_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smallint, @date_purged char(8), @time_purged varchar(20) 
) as 

CREATE TABLE #temp ( timestamp varbinary(8) NULL, company_id smallint NULL, date_created datetime NULL, co_asset_id int NULL, asset_ctrl_num varchar(16) NULL, asset_description varchar(40) NULL, activity_state tinyint, mass_maintenance_id int, mass_description varchar(16) NULL, comment varchar(255) NULL, user_name varchar(16) NULL, acquisition_date datetime NULL, disposition_date datetime NULL, original_cost float NULL, lp_fiscal_period_end datetime NULL, lp_accum_depr float NULL, lp_current_cost float NULL, updated_by smallint )

declare @rowsfound smallint 
select 	@rowsfound = 0 

declare @MSKdt 	datetime 
SELECT 	@MSKdt = @date_purged + " " + @time_purged

 
select 	@MSKdt = max(date_created) 
from 	ampurge_vw 
where	date_created < @MSKdt
AND 	company_id	 = @company_id 

while @MSKdt is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
			timestamp,
		 	company_id, date_created, co_asset_id , asset_ctrl_num, asset_description, activity_state, mass_maintenance_id, mass_description, comment , user_name, acquisition_date, disposition_date, original_cost, lp_fiscal_period_end, lp_accum_depr , lp_current_cost, updated_by 
	from 	ampurge_vw
	where 	date_created = @MSKdt 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select 	@MSKdt 			= max(date_created) 
	from 	ampurge_vw 
	where 	date_created 	< @MSKdt 
	AND		company_id		= @company_id
end 

select 
		timestamp, company_id, date_purged=CONVERT(char(8), date_created, 112), time_purged=CONVERT(varchar(20), date_created, 114), co_asset_id, asset_ctrl_num, asset_description, activity_state, mass_maintenance_id, mass_description, comment, user_name, date_acquisition=CONVERT(char(8), acquisition_date, 112), date_disposition=CONVERT(char(8), disposition_date, 112), original_cost, lp_fiscal_period_end=CONVERT(char(8), lp_fiscal_period_end, 112), lp_accum_depr=-lp_accum_depr, lp_current_cost, updated_by 
from 	#temp 
order by date_created desc

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwPrev_sp] TO [public]
GO
