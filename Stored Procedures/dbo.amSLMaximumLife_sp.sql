SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSLMaximumLife_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	 
	@from_date 			smApplyDate, 		
	@convention_id		smConventionID,		
	@salvage_value 		smMoneyZero, 		
	@use_addition_info 	smLogical, 				
	@acquisition_date	smApplyDate,		
	@placed_date		smApplyDate,		
	@curr_precision		smallint,			
	@depr_expense 	 	smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0 
)
AS 

DECLARE 
	@return_status 	smErrorCode,
	@sl_percentage 		smMoneyZero, 
	@sl_specified_life 	smMoneyZero 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslmax.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "

EXEC @return_status = amSLPercentage_sp 
						@co_asset_book_id,
						@from_date,
						@convention_id,
						@salvage_value,
						@use_addition_info,
						@acquisition_date,
						@placed_date,
						@curr_precision,
						@sl_percentage 	OUTPUT,
						@debug_level 

IF ( @return_status != 0 )
	RETURN @return_status

EXEC @return_status = amSLSpecifiedLife_sp 
						@co_asset_book_id,
						@from_date,
						@convention_id,
						@salvage_value,
						@use_addition_info,
						@acquisition_date,
						@placed_date,
						@curr_precision,
						@sl_specified_life 	OUTPUT,
						@debug_level 

IF ( @return_status != 0 )
	RETURN @return_status

 
IF @sl_percentage > @sl_specified_life 
	SELECT @depr_expense = @sl_percentage 
ELSE 
	SELECT @depr_expense = @sl_specified_life 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslmax.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSLMaximumLife_sp] TO [public]
GO
