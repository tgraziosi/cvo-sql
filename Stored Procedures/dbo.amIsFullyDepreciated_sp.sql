SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amIsFullyDepreciated_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 				
	@method_id 			smDeprMethodID, 			 
	@apply_date 		smApplyDate, 					 
	@salvage_value 		smMoneyZero, 					 
	@cost 				smMoneyZero, 					 
	@accum_depr 		smMoneyZero, 			 		 
	@curr_precision		smallint,						
	@depr_expense 	 	smMoneyZero 	= 0.0 OUTPUT,	 
	@debug_level		smDebugLevel 	= 0 			
)
AS 

DECLARE 
	@result			 	smErrorCode, 
	@end_life_date 		smApplyDate,
	@check_end_life		smLogical

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amflldpr.sp" + ", line " + STR( 135, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			apply_date 			= @apply_date,
			salvage_value 		= @salvage_value,
			cost 				= @cost,
			accum_depr 			= @accum_depr,
			depr_expense 		= @depr_expense 

SELECT	@check_end_life = 0

IF @cost >= 0.0
BEGIN
	
	IF (@cost - @salvage_value) < (-@accum_depr + @depr_expense)
	BEGIN 
		IF @debug_level > 3
			SELECT "cost - sv < accum depr + depr exp"
		
		IF @cost - @salvage_value < -@accum_depr 
			SELECT @depr_expense = 0.0 
		ELSE 
			SELECT @depr_expense = (SIGN((@cost - @salvage_value + @accum_depr)) * ROUND(ABS((@cost - @salvage_value + @accum_depr)) + 0.0000001, @curr_precision))
	END 
	ELSE
		SELECT	@check_end_life = 1

END
ELSE
BEGIN
	
	IF (@cost - @salvage_value) > (-@accum_depr + @depr_expense)
	BEGIN 
		IF @debug_level > 3
			SELECT "cost - sv > accum depr + depr exp"
		
		IF @cost - @salvage_value > -@accum_depr 
			SELECT @depr_expense = 0.0 
		ELSE 
			SELECT @depr_expense = (SIGN((@cost - @salvage_value + @accum_depr)) * ROUND(ABS((@cost - @salvage_value + @accum_depr)) + 0.0000001, @curr_precision))
	END
	ELSE
		SELECT	@check_end_life = 1
	 
END

IF @check_end_life = 1
BEGIN 
	IF @debug_level > 3
		SELECT "Checking end life date"

	 
	
	IF (@method_id = 2)
	OR (@method_id = 3)
	OR (@method_id = 5)
	BEGIN 
		
		 
		EXEC	@result = amGetEndLifeDate_sp
							@co_asset_book_id,
							@apply_date,
							@end_life_date 	OUTPUT

		IF @result <> 0
			RETURN @result
		
		
		 
		IF @end_life_date <= @apply_date 
		BEGIN 
			IF @cost > 0.0
			BEGIN
				IF @cost - @salvage_value < -@accum_depr 
					SELECT @depr_expense = 0.0 
				ELSE 
					SELECT @depr_expense = (SIGN((@cost - @salvage_value + @accum_depr)) * ROUND(ABS((@cost - @salvage_value + @accum_depr)) + 0.0000001, @curr_precision))
			END
			ELSE
			BEGIN
				IF @cost - @salvage_value > -@accum_depr 
					SELECT @depr_expense = 0.0 
				ELSE 
					SELECT @depr_expense = (SIGN((@cost - @salvage_value + @accum_depr)) * ROUND(ABS((@cost - @salvage_value + @accum_depr)) + 0.0000001, @curr_precision))
			END
		END 
	END 
END 

IF @debug_level > 3
	SELECT 	depr_expense 	= @depr_expense 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amflldpr.sp" + ", line " + STR( 242, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amIsFullyDepreciated_sp] TO [public]
GO
