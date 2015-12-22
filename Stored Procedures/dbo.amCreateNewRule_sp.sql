SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateNewRule_sp] 
(
 @co_asset_book_id 	smSurrogateKey, 		
	@book_code				smBookCode,				
	@effective_date			smApplyDate,			
	@category_code			smCategoryCode,			
	@user_id				smUserID,				
	@placed_date			smApplyDate,			
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result				smErrorCode,
	@message 			smErrorLongDesc,
	@asset_ctrl_num		smControlNumber,			
	@date_str			smErrorParam,				
	@depr_rule_code 	smDeprRuleCode, 			
	@salvage 			smMoneyZero, 				
	@def_percent 		smPercentage,
	@def_value			smMoneyZero, 
	@end_life_date 		smApplyDate, 
	@cost				smMoneyZero, 				
	@rounding_factor 	float,
	@curr_precision		smallint
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrnwrl.sp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "
 
EXEC @result = amGetCurrencyPrecision_sp 
					@curr_precision OUTPUT,	
					@rounding_factor OUTPUT 	

IF @result <> 0
	RETURN @result

SELECT 	@depr_rule_code = NULL

SELECT 	@depr_rule_code = depr_rule_code
FROM 	amcatbk 
WHERE 	category_code 	= @category_code 
AND 	book_code 		= @book_code 
AND 	effective_date 	= 
			(SELECT MAX(effective_date)
			FROM 	amcatbk 
			WHERE 	category_code 	= @category_code 
			AND 	book_code 		= @book_code 
			AND 	effective_date 	<= @effective_date)

IF @depr_rule_code IS NOT NULL 
BEGIN 

	IF @debug_level >= 3
		SELECT 	depr_rule_code 	= @depr_rule_code

	
	SELECT	@cost 				= current_cost
	FROM	amastprf
	WHERE	co_asset_book_id 	= @co_asset_book_id
	AND		fiscal_period_end	= (SELECT 	MAX(fiscal_period_end)
									FROM 	amastprf
									WHERE	co_asset_book_id 	= @co_asset_book_id
									AND		fiscal_period_end	< @effective_date)

	IF @cost IS NULL
	BEGIN
		
		SELECT	@cost 				= orig_amount_capitalised
		FROM	amastbk
		WHERE	co_asset_book_id	= @co_asset_book_id

		IF @cost IS NULL
			SELECT	@cost = 0
	END
	
	 
	SELECT 	@def_percent 	= def_salvage_percent,
			@def_value		= def_salvage_value
	FROM 	amdprrul 
	WHERE 	depr_rule_code 	= @depr_rule_code 
	
	IF @def_percent = 0
		SELECT @salvage = @def_value
	ELSE
		SELECT @salvage = (SIGN(@cost * @def_percent / 100) * ROUND(ABS(@cost * @def_percent / 100) + 0.0000001, @curr_precision))
	
	IF @debug_level >= 3
		SELECT 	cost 		= @cost, 
				def_percent = @def_percent, 
				salvage 	= @salvage 

	 
	IF @placed_date IS NOT NULL 
	BEGIN 
		EXEC @result = amCalcEndLifeDate_sp 
						@depr_rule_code, 
						@placed_date, 
						@end_life_date OUTPUT,
						@debug_level 
		IF @result <> 0 
			RETURN @result 
	END 
	ELSE 
		SELECT @end_life_date = NULL 
	
	IF @debug_level >= 3
		SELECT 	end_life_date = @end_life_date 

	IF EXISTS(SELECT	effective_date
				FROM	amdprhst
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		effective_date		= @effective_date)
	BEGIN
		IF @debug_level >= 3
			SELECT 	"Updating amdprhst"
			 
		 
		UPDATE	amdprhst
		SET		last_modified_date 	= GETDATE(),
				modified_by			= @user_id,
				depr_rule_code		= @depr_rule_code,
				salvage_value		= @salvage,
				end_life_date		= @end_life_date
		FROM	amdprhst
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		effective_date		= @effective_date
		
		SELECT	@result = @@error
		IF	@result <> 0
		BEGIN
				IF @debug_level >= 3
				SELECT 	"amCreateNewRule_sp: Update of amdprhst failed" 
			RETURN @result
		END
	END
	ELSE
	BEGIN
		IF @debug_level >= 3
			SELECT 	"Inserting into amdprhst"
		
		 
		INSERT INTO amdprhst 
		(
				co_asset_book_id,
				effective_date,
				last_modified_date,
				modified_by,
				depr_rule_code,
				limit_rule_code,
				salvage_value,
				end_life_date
		)
		VALUES 
		(
				@co_asset_book_id, 
				@effective_date,
				GETDATE(), 			
				@user_id,
				@depr_rule_code,
				"",					 
				@salvage,
				@end_life_date
		)
		SELECT @result = @@error 
		IF @result <> 0 
		BEGIN
			IF @debug_level >= 3
				SELECT 	"amCreateNewRule_sp: Insert into amdprhst failed" 
			RETURN @result 
		END
	END

END
ELSE
BEGIN
	IF @debug_level >= 3
		SELECT 	"amCreateNewRule_sp: Can't find rule code" 

	SELECT	@asset_ctrl_num 	= a.asset_ctrl_num,
			@book_code			= ab.book_code
	FROM	amasset a,
			amastbk	ab
	WHERE	ab.co_asset_book_id	= @co_asset_book_id
	AND		ab.co_asset_id		= a.co_asset_id

	SELECT	@date_str = CONVERT(char(255), @effective_date)
		
	EXEC 		amGetErrorMessage_sp 20091, "tmp/amcrnwrl.sp", 255, @asset_ctrl_num, @book_code, @category_code, @date_str, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20091 @message 

END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcrnwrl.sp" + ", line " + STR( 261, 5 ) + " -- EXIT: " 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateNewRule_sp] TO [public]
GO
