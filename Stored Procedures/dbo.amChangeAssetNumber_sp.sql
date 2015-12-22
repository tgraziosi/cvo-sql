SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amChangeAssetNumber_sp] 
( 	
	@co_asset_id 		smSurrogateKey, 	
	@old_asset_ctrl_num	smControlNumber,	
	@new_asset_ctrl_num smControlNumber, 	
	@user_id			smUserID,			
	@timestamp		 	timestamp OUT,		
	@debug_level		smDebugLevel	= 0	
) 
AS 

DECLARE 
	@result 			smErrorCode,
	@date_of_change		smApplyDate

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgast.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

SELECT	@date_of_change = GETDATE()


BEGIN TRANSACTION

	
	UPDATE	amasset
	SET		asset_ctrl_num		= @new_asset_ctrl_num,
			modified_by			= @user_id,
			last_modified_date	= @date_of_change
	FROM	amasset
	WHERE	co_asset_id			= @co_asset_id
	
	SELECT @result = @@error 
	IF @result <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @result
	END

	
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		7,
		GETDATE(),
		@old_asset_ctrl_num,
		@new_asset_ctrl_num,
		@date_of_change,
		@user_id
	)

	SELECT @result = @@error 
	IF @result <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @result
	END
		
COMMIT TRANSACTION 


SELECT	@timestamp 	= timestamp
FROM	amasset
WHERE	co_asset_id	= @co_asset_id

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amchgast.sp" + ", line " + STR( 122, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amChangeAssetNumber_sp] TO [public]
GO
