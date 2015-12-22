SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCalculateSalvageValue_sp] 
(
 @depr_rule_code 	smDeprRuleCode, 		
 @co_asset_book_id 	smSurrogateKey, 		
	@apply_date		 	smApplyDate, 			
 @cur_precision			smallint,				
 @salvage_value 	smMoneyZero OUTPUT, 	
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result					smErrorCode,
	@current_cost 	 		smMoneyZero,
	@def_value				smMoneyZero,
	@def_percent			smPercentage,
	@fiscal_period_end		smApplyDate,
	@rounding_factor		float 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcalcvs.sp" + ", line " + STR( 86, 5 ) + " -- ENTRY: "

 
SELECT 	@def_percent 	= def_salvage_percent,
		@def_value		= def_salvage_value
FROM 	amdprrul 
WHERE 	depr_rule_code 	= @depr_rule_code 

IF @@rowcount = 0 
	SELECT @salvage_value = 0.0
ELSE
BEGIN
	IF (ABS((@def_percent)-(0.0)) < 0.0000001)
		SELECT @salvage_value = @def_value
	ELSE
	BEGIN
		
		EXEC @result = amGetFiscalPeriod_sp 
							@apply_date, 
							1, 
							@fiscal_period_end OUTPUT 

		IF @result <> 0 
			RETURN @result
		
		SELECT 	@current_cost 	= (SIGN(ISNULL(SUM(amount),0.0)) * ROUND(ABS(ISNULL(SUM(amount),0.0)) + 0.0000001, @cur_precision))
		FROM 	amvalues 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		AND 	apply_date			<= @fiscal_period_end 
		AND		account_type_id		= 0

		IF @debug_level >= 5
			SELECT 	apply_date,
					trx_type,
					amount
			FROM 	amvalues 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	apply_date			<= @fiscal_period_end 
			AND		account_type_id		= 0
		
		IF @current_cost IS NULL
			SELECT	@current_cost	= 0.0 

		SELECT @salvage_value = (SIGN(@current_cost * @def_percent / 100.00) * ROUND(ABS(@current_cost * @def_percent / 100.00) + 0.0000001, @cur_precision)) 
	END
END
		
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcalcvs.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCalculateSalvageValue_sp] TO [public]
GO
