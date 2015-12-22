SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amAddOrModifyRule_sp]
(
	@co_asset_id 		smSurrogateKey,			
	@book_code 			smBookCode,				
	@effective_date		smISODate,				
	@depr_rule_code		smDeprRuleCode,			
	@user_id			smUserID,				
	@debug_level 		smDebugLevel = 0		
) 
AS

DECLARE 
	@rowcount 				smCounter,
	@result 				smErrorCode,
	@param					smErrorParam,
	@message 				smErrorLongDesc,
	@co_asset_book_id		smSurrogateKey,
	@asset_ctrl_num			smControlNumber,
	@effective_date_dt		smApplyDate,
	@placed_date			smApplyDate,
	@end_life_date			smApplyDate,
	@salvage_value			smMoneyZero,
	@rounding_factor 	 	float,
	@curr_precision			smallint,
	@last_posted_depr_date	smApplyDate
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amaddrul.sp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "

IF 	@effective_date IS NULL
OR	@book_code IS NULL
BEGIN
	EXEC	 	amGetErrorMessage_sp 20097, "tmp/amaddrul.sp", 83, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20097 @message
	RETURN 		20097
END

EXEC @result = amGetCurrencyPrecision_sp 
					@curr_precision OUTPUT,	
					@rounding_factor OUTPUT 	

IF @result <> 0
	RETURN @result

SELECT 	@co_asset_book_id 	= 0,
		@effective_date_dt	= CONVERT(datetime, @effective_date)

SELECT 	@co_asset_book_id		= co_asset_book_id,
		@placed_date			= placed_in_service_date,
		@last_posted_depr_date	= last_posted_depr_date
FROM	amastbk
WHERE	co_asset_id				= @co_asset_id
AND		book_code				= @book_code

IF @co_asset_book_id = 0
BEGIN
	SELECT 	@asset_ctrl_num = asset_ctrl_num
	FROM	amasset
	WHERE	co_asset_id		= @co_asset_id

	SELECT @rowcount= @@rowcount

	IF @rowcount = 0
	BEGIN
		SELECT @param = RTRIM(CONVERT(char(255), @co_asset_id))

		EXEC	 	amGetErrorMessage_sp 20063, "tmp/amaddrul.sp", 117, @param, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20063 @message
		RETURN 		20063
	END
	ELSE
	BEGIN
		EXEC	 	amGetErrorMessage_sp 20062, "tmp/amaddrul.sp", 123, @asset_ctrl_num, @book_code, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20062 @message
		RETURN 		20062
	END

END

IF 	@last_posted_depr_date 	IS NOT NULL
AND	@effective_date_dt		<= @last_posted_depr_date
BEGIN
	SELECT 	@asset_ctrl_num = asset_ctrl_num
	FROM	amasset
	WHERE	co_asset_id		= @co_asset_id

	SELECT @rowcount= @@rowcount

	IF @rowcount = 0
	BEGIN
		SELECT @param = RTRIM(CONVERT(char(255), @co_asset_id))

		EXEC	 	amGetErrorMessage_sp 20063, "tmp/amaddrul.sp", 143, @param, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20063 @message
		RETURN 		20063
	END

	SELECT @param = RTRIM(CONVERT(char(255), @effective_date_dt, 107))

	EXEC	 	amGetErrorMessage_sp 20099, "tmp/amaddrul.sp", 150, @asset_ctrl_num, @book_code, @param, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20099 @message
	RETURN 		20099
END
ELSE
BEGIN
	IF @depr_rule_code IS NOT NULL
	BEGIN
		
		IF @placed_date IS NOT NULL 
		BEGIN 
			EXEC @result = amCalcEndLifeDate_sp 
							@depr_rule_code, 
							@placed_date, 
							@end_life_date OUTPUT 
			IF @result <> 0 
				RETURN @result 
		END 
		ELSE 
			SELECT @end_life_date = NULL 

		
		EXEC @result = amCalculateSalvageValue_sp 
						 @depr_rule_code,
						 @co_asset_book_id,
							@effective_date_dt,
						 @curr_precision,
						 @salvage_value OUTPUT,
							@debug_level		 

		IF @result <> 0 
			RETURN @result 

		
		IF EXISTS (SELECT 	depr_rule_code
					FROM	amdprhst
					WHERE	co_asset_book_id	= @co_asset_book_id
					AND		effective_date		= @effective_date_dt)
		BEGIN
			
			IF EXISTS (SELECT 	depr_rule_code
						FROM	amdprhst
						WHERE	co_asset_book_id	= @co_asset_book_id
						AND		effective_date		= @effective_date_dt
						AND		posting_flag		= 0)
			BEGIN
				UPDATE	amdprhst
				SET		last_modified_date 	= GETDATE(),
						modified_by			= @user_id,
						depr_rule_code		= @depr_rule_code,
						salvage_value		= @salvage_value,
						end_life_date		= @end_life_date
				FROM	amdprhst
				WHERE	co_asset_book_id 	= @co_asset_book_id
				AND		effective_date		= @effective_date_dt
				AND		posting_flag		= 0
				
				SELECT	@result = @@error
				IF	@result <> 0
					RETURN @result
			END
		END
		ELSE
		BEGIN
			 
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
					@salvage_value,
					@end_life_date
			)
			SELECT @result = @@error 
			IF @result <> 0 
				RETURN @result 

		END
	END
	ELSE
	BEGIN
		
		IF EXISTS (SELECT 	depr_rule_code
					FROM	amdprhst
					WHERE	co_asset_book_id	= @co_asset_book_id
					AND		effective_date		= @effective_date_dt
					AND		posting_flag		= 0)
		BEGIN
			DELETE	amdprhst
			FROM	amdprhst
			WHERE	co_asset_book_id 	= @co_asset_book_id
			AND		effective_date		= @effective_date_dt
			AND		posting_flag		= 0
			
			SELECT	@result = @@error
			IF	@result <> 0
				RETURN @result
		END
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amaddrul.sp" + ", line " + STR( 279, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amAddOrModifyRule_sp] TO [public]
GO
