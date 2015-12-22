SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amActivateNewAsset_sp] 
(
	@co_asset_id 			smSurrogateKey, 	
	@asset_ctrl_num 		smControlNumber, 	
	@acquisition_date		smApplyDate,		
	@debug_level			smDebugLevel 	= 0	
)
AS 

DECLARE 
	@result    				smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@co_asset_book_id 		smSurrogateKey, 	
	@asset_ok 				smLogical 			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdonew.cpp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	co_asset_id 		= @co_asset_id 	
 


 
SELECT 	@asset_ok 		= 1




SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
FROM	amastbk
WHERE	co_asset_id 		= @co_asset_id

WHILE @co_asset_book_id IS NOT NULL
BEGIN
	
	


	IF NOT EXISTS (SELECT 	depr_rule_code
					FROM 	amdprhst
					WHERE	co_asset_book_id 	= @co_asset_book_id
					AND		effective_date 		<= @acquisition_date)

	BEGIN 
		SELECT 		@asset_ok = 0 
		EXEC	 	amGetErrorMessage_sp 
								20170, "amdonew.cpp", 97, 
								@asset_ctrl_num, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20170 @message 
		BREAK		
	END 

	


	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	amastbk
	WHERE	co_asset_id 		= @co_asset_id
	AND		co_asset_book_id 	> @co_asset_book_id

END	

IF	(@asset_ok = 1)
BEGIN
	

 
	UPDATE 	amasset 
	SET 	activity_state 		= 0,
			rem_quantity		= orig_quantity 
	FROM 	amasset inner join amOrganization_vw vw
		on amasset.org_id = vw.org_id 
	WHERE 	co_asset_id	 		= @co_asset_id 

	SELECT @result = @@error 
	IF @result <> 0 
		RETURN 	@result 
		
	


	EXEC 		amGetErrorMessage_sp 
						20400, "amdonew.cpp", 134, 
						@asset_ctrl_num, 
						@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20400 @message 

END 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdonew.cpp" + ", line " + STR( 141, 5 ) + " -- EXIT: "

RETURN 	0 
GO
GRANT EXECUTE ON  [dbo].[amActivateNewAsset_sp] TO [public]
GO
