SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprrulPrevRow_sp] 
( 
	@depr_rule_code smDeprRuleCode 
) as 


declare @MSKdepr_rule_code smDeprRuleCode 
select 	@MSKdepr_rule_code = @depr_rule_code 
select 	@MSKdepr_rule_code = max(depr_rule_code) 
from 	amdprrul 
where 	depr_rule_code < @MSKdepr_rule_code 

select 
		timestamp, depr_rule_code, rule_description, depr_method_id, convention_id, units_of_measure, service_life, useful_life_end_date = convert(char(8), useful_life_end_date,112), annual_depr_rate, immediate_depr_rate, first_year_depr_rate, def_salvage_percent, def_salvage_value, override_salvage, depr_below_salvage, p_and_l_on_partial_disp, use_convention_on_disp, max_asset_value
from 	amdprrul
where 	depr_rule_code = @MSKdepr_rule_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprrulPrevRow_sp] TO [public]
GO
