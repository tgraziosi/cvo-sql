SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amLogAssetClsChanges_sp] 
(
 @co_asset_id 	smSurrogateKey, 						
	@last_modified_date smApplyDate, 							
	@modified_by 		smUserID 				= 0,			
	@classification_id	smSurrogateKey,							
	@old_cls_code 		smClassificationCode 	= NULL,			
	@new_cls_code 		smClassificationCode 	= NULL,			
 	@changed 			smLogical 				= 0 OUTPUT,	
	@debug_level		smDebugLevel			= 0				
)
AS 

DECLARE @error 		smErrorCode,
		@rowcount	smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlogcls.sp" + ", line " + STR( 77, 5 ) + " -- ENTRY: " 

IF @old_cls_code <> @new_cls_code 
BEGIN 
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
		1000 + @classification_id,
		@last_modified_date,
		@old_cls_code,
		@new_cls_code,
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error, @rowcount = @@rowcount
	IF 	@error <> 0 
	OR	@rowcount <> 1
		RETURN @error 

	SELECT @changed = 1 
END 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlogcls.sp" + ", line " + STR( 111, 5 ) + " -- EXIT: " 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amLogAssetClsChanges_sp] TO [public]
GO
