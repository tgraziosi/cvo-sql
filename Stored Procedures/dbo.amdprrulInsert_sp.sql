SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprrulInsert_sp] 
( 
	@depr_rule_code smDeprRuleCode, @rule_description smStdDescription, @depr_method_id smDeprMethodID, @convention_id smConventionID, @units_of_measure smUnitsOfMeasure, @service_life smLife, @useful_life_end_date varchar(30), @annual_depr_rate smRate, @immediate_depr_rate smRate, @first_year_depr_rate smRate, @def_salvage_percent smPercentage, @def_salvage_value smMoneyZero, @override_salvage smLogicalFalse, @depr_below_salvage smLogicalFalse, @p_and_l_on_partial_disp smLogicalTrue, @use_convention_on_disp smLogicalTrue, @max_asset_value smMoneyZero
	) as 

declare @error int 

 

SELECT @useful_life_end_date = RTRIM(@useful_life_end_date) IF @useful_life_end_date = "" SELECT @useful_life_end_date = NULL

 

insert into amdprrul 
( 
	depr_rule_code, rule_description, depr_method_id, convention_id, units_of_measure, service_life, useful_life_end_date, annual_depr_rate, immediate_depr_rate, first_year_depr_rate, def_salvage_percent, def_salvage_value, override_salvage, depr_below_salvage, p_and_l_on_partial_disp, use_convention_on_disp, max_asset_value
)
values 
( 
	@depr_rule_code,
	@rule_description,
	@depr_method_id,
	@convention_id,
	@units_of_measure,
	@service_life,
	@useful_life_end_date,
	@annual_depr_rate,
	@immediate_depr_rate,
	@first_year_depr_rate,
	@def_salvage_percent,
	@def_salvage_value,
	@override_salvage,
	@depr_below_salvage,
	@p_and_l_on_partial_disp,
	@use_convention_on_disp,
	@max_asset_value 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprrulInsert_sp] TO [public]
GO
