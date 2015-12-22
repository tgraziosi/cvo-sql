SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateAssetBook_sp]
(
	@co_asset_id			smSurrogateKey,			
	@new_book_code			smBookCode,				
	@old_book_code			smBookCode,				
	@copy_rules				smLogical,				
	@depr_to_copied_bk		smLogical,				
	@depr_to_date			smApplyDate,			
	@user_id				smUserID,				
	@debug_level			smDebugLevel	= 0		
) 
AS

DECLARE 
	@result					smErrorCode,
	@is_valid				smLogical

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcreabk.sp" + ", line " + STR( 83, 5 ) + " -- ENTRY: "

EXEC @result = amCheckAssetBook_sp
					@co_asset_id,
					@new_book_code,
					@old_book_code,
					@copy_rules,
					@depr_to_copied_bk,					 
					@depr_to_date	OUTPUT,
					@is_valid		OUTPUT,
					@debug_level
IF @result <> 0
	RETURN @result
					
IF @debug_level >= 3
	SELECT depr_to_date = @depr_to_date
	
	IF @is_valid = 1
BEGIN
	IF @copy_rules = 0
		SELECT @depr_to_date = NULL
		
	EXEC @result = amCopyAssetBook_sp
					@co_asset_id,
					@new_book_code,
					@old_book_code,
					@copy_rules,
					@depr_to_date,
					@user_id,
					@debug_level
	IF @result <> 0
		RETURN @result

END	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcreabk.sp" + ", line " + STR( 118, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateAssetBook_sp] TO [public]
GO
