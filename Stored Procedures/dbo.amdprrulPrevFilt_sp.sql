SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprrulPrevFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@depr_rule_code smDeprRuleCode, 
	@depr_rule_code_filter smDeprRuleCode 
) 
as 

create table #temp ( timestamp varbinary(8) null, depr_rule_code char(8) null, rule_description varchar(40) null, depr_method_id smallint null, convention_id tinyint null, units_of_measure varchar(16) null, service_life float null, useful_life_end_date datetime null, annual_depr_rate float null, immediate_depr_rate float null, first_year_depr_rate float null, def_salvage_percent float null, def_salvage_value float null, override_salvage tinyint null, depr_below_salvage tinyint null, p_and_l_on_partial_disp tinyint null, use_convention_on_disp tinyint null, max_asset_value float null )

declare @rowsfound smallint 
declare @MSKdepr_rule_code smDeprRuleCode 

select 	@rowsfound = 0 
select 	@MSKdepr_rule_code = @depr_rule_code 
select	@MSKdepr_rule_code 	= max(depr_rule_code) 
from 	amdprrul 
where 	depr_rule_code 		< @MSKdepr_rule_code 
and 	depr_rule_code 		like RTRIM(@depr_rule_code_filter)

while @MSKdepr_rule_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select 	 
			timestamp,
			depr_rule_code, rule_description, depr_method_id, convention_id, units_of_measure, service_life, useful_life_end_date, annual_depr_rate, immediate_depr_rate, first_year_depr_rate, def_salvage_percent, def_salvage_value, override_salvage, depr_below_salvage, p_and_l_on_partial_disp, use_convention_on_disp, max_asset_value
	from 	amdprrul 
	where 	depr_rule_code = @MSKdepr_rule_code 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select 	@MSKdepr_rule_code 	= max(depr_rule_code) 
	from 	amdprrul 
	where 	depr_rule_code		< @MSKdepr_rule_code 
 	and 	depr_rule_code		like RTRIM(@depr_rule_code_filter)
end 

select 
	timestamp, depr_rule_code, rule_description, depr_method_id, convention_id, units_of_measure, service_life, useful_life_end_date = convert(char(8), useful_life_end_date,112), annual_depr_rate, immediate_depr_rate, first_year_depr_rate, def_salvage_percent, def_salvage_value, override_salvage, depr_below_salvage, p_and_l_on_partial_disp, use_convention_on_disp, max_asset_value 
from #temp 
order by depr_rule_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprrulPrevFilt_sp] TO [public]
GO
