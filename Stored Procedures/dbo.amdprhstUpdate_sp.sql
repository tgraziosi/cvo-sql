SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amdprhstUpdate_sp] 
( 
	@timestamp 	timestamp,			
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
) 
AS 
DECLARE 
	@rowcount 				smCounter, 
	@error 					smErrorCode, 
	@ts 					timestamp, 
	@message 				smErrorLongDesc,
	@last_modified_by		smUserID

SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL
SELECT @end_life_date = RTRIM(@end_life_date) IF @end_life_date = "" SELECT @end_life_date = NULL


UPDATE 	amdprhst 
SET 
		last_modified_date 	= @last_modified_date,
		modified_by 	= @modified_by,
		depr_rule_code 	= @depr_rule_code,
		salvage_value 	= @salvage_value
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 	= @effective_date 
AND 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 				= timestamp,
			@last_modified_by	= modified_by 
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 		= @effective_date 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amdphsup.sp", 132, amdprhst, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 
	IF @ts <> @timestamp 
	BEGIN 
			
		IF @last_modified_by < 0	
		BEGIN
			UPDATE 	amdprhst 
			SET 
					last_modified_date 	= @last_modified_date,
					modified_by 	= @modified_by,
					depr_rule_code 	= @depr_rule_code,
					salvage_value 	= @salvage_value
			WHERE 	co_asset_book_id 	= @co_asset_book_id 
			AND 	effective_date 	= @effective_date 

			SELECT @error = @@error 
			IF @error <> 0  
				RETURN @error 
		END
		ELSE
		BEGIN
			EXEC 		amGetErrorMessage_sp 20003, "tmp/amdphsup.sp", 162, amdprhst, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20003 @message 
			RETURN 		20003 
		END
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amdprhstUpdate_sp] TO [public]
GO
