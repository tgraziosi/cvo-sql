SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imClsDel_sp] 
( 
	@company_id				smallint,			
	@classification_name	varchar(40),		
	@asset_ctrl_num			char(16),				
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@co_asset_id			int,				
	@classification_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imclsdel.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "


EXEC @result = imClsVal_sp
					@action 				= 1,
					@company_id				= @company_id,
					@classification_name	= @classification_name,
					@asset_ctrl_num			= @asset_ctrl_num,
					@stop_on_error			= @stop_on_error,
					@is_valid				= @is_valid		OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN
	
	SELECT	@co_asset_id	= co_asset_id
	FROM	amasset 
	WHERE	company_id		= @company_id
	AND		asset_ctrl_num	= @asset_ctrl_num

	
	SELECT	@classification_id	= classification_id
	FROM	amclshdr
	WHERE	company_id			= @company_id
	AND		classification_name	= @classification_name

	
	DELETE
	FROM 	amastcls
	WHERE	company_id			= @company_id
	AND		co_asset_id 		= @co_asset_id
	AND		classification_id	= @classification_id
			
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imclsdel.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imClsDel_sp] TO [public]
GO
