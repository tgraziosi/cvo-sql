SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprrulUpdate_sp] 
( 
	@timestamp timestamp,
	@depr_rule_code smDeprRuleCode, @rule_description smStdDescription, @depr_method_id smDeprMethodID, @convention_id smConventionID, @units_of_measure smUnitsOfMeasure, @service_life smLife, @useful_life_end_date varchar(30), @annual_depr_rate smRate, @immediate_depr_rate smRate, @first_year_depr_rate smRate, @def_salvage_percent smPercentage, @def_salvage_value smMoneyZero, @override_salvage smLogicalFalse, @depr_below_salvage smLogicalFalse, @p_and_l_on_partial_disp smLogicalTrue, @use_convention_on_disp smLogicalTrue, @max_asset_value smMoneyZero
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)

SELECT @useful_life_end_date = RTRIM(@useful_life_end_date) IF @useful_life_end_date = "" SELECT @useful_life_end_date = NULL

update amdprrul set 
	rule_description = @rule_description,
	depr_method_id = @depr_method_id,
	convention_id					= 		@convention_id,
	units_of_measure = @units_of_measure,
	service_life = @service_life,
	useful_life_end_date = @useful_life_end_date,
	annual_depr_rate = @annual_depr_rate,
	immediate_depr_rate = @immediate_depr_rate,
	first_year_depr_rate = @first_year_depr_rate,
	def_salvage_percent = @def_salvage_percent,
	def_salvage_value				= 		@def_salvage_value,
	override_salvage = @override_salvage,
	depr_below_salvage = @depr_below_salvage,
	p_and_l_on_partial_disp = @p_and_l_on_partial_disp,
	use_convention_on_disp = @use_convention_on_disp,
	max_asset_value = @max_asset_value 
where 
	depr_rule_code = @depr_rule_code and 
	timestamp = @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amdprrul where 
	depr_rule_code = @depr_rule_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amdprlup.sp", 117, amdprrul, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC	 	amGetErrorMessage_sp 20003, "tmp/amdprlup.sp", 123, amdprrul, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprrulUpdate_sp] TO [public]
GO
