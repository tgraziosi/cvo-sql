SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprhstInsert_sp] 
( 
 	 
	@co_asset_book_id 	smSurrogateKey, 
	@effective_date 	varchar(30), 
	@last_modified_date 	varchar(30), 
	@modified_by 	smUserID, 
	@posting_flag 	smPostingState, 
	@depr_rule_code 	smDeprRuleCode, 
	@limit_rule_code 	smLimitRuleCode, 
	@salvage_value 	smMoneyZero, 
	@catch_up_diff 	smLogicalFalse, 
	@end_life_date 	varchar(30), 
	@switch_to_sl_date 	varchar(30)
) as 

declare @error int 

 

SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL
SELECT @end_life_date = RTRIM(@end_life_date) IF @end_life_date = "" SELECT @end_life_date = NULL
SELECT @switch_to_sl_date = RTRIM(@switch_to_sl_date) IF @switch_to_sl_date = "" SELECT @switch_to_sl_date = NULL



 

insert into amdprhst 
( 
	co_asset_book_id,
	effective_date,
	last_modified_date,
	modified_by,
	posting_flag,
	depr_rule_code,
	limit_rule_code,
	salvage_value,
	catch_up_diff,
	end_life_date,
	switch_to_sl_date 
)
values 
( 
	@co_asset_book_id,
	@effective_date,
	@last_modified_date,
	@modified_by,
	@posting_flag,
	@depr_rule_code,
	@limit_rule_code,
	@salvage_value,
	@catch_up_diff,
	@end_life_date,
	@switch_to_sl_date 
)

 
 
 

return @@error 		 
GO
GRANT EXECUTE ON  [dbo].[amdprhstInsert_sp] TO [public]
GO
