SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amdprrulFirstFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@depr_rule_code_filter smDeprRuleCode,
	@debug_level					smDebugLevel	= 0 
) 
AS 

SET ROWCOUNT @rowsrequested 

SELECT 
	 timestamp, depr_rule_code, rule_description, depr_method_id, convention_id, units_of_measure, service_life, useful_life_end_date = convert(char(8), useful_life_end_date,112), annual_depr_rate, immediate_depr_rate, first_year_depr_rate, def_salvage_percent, def_salvage_value, override_salvage, depr_below_salvage, p_and_l_on_partial_disp, use_convention_on_disp, max_asset_value 
FROM 	amdprrul 
WHERE 	depr_rule_code 		LIKE RTRIM(@depr_rule_code_filter) 

SET ROWCOUNT 0

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amdprrulFirstFilt_sp] TO [public]
GO
