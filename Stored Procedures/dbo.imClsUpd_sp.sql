SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imClsUpd_sp] 
( 
	@company_id				smallint,			
	@classification_name	varchar(40),		
	@asset_ctrl_num			char(16),				
	@classification_code	char(8),			
	@last_modified_date		char(8)		= NULL,	
	@modified_by			int			= 1,	
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@co_asset_id			int,				
	@classification_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imclsupd.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "


IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)


EXEC @result = imClsVal_sp
					2,
					@company_id,
					@classification_name,
					@asset_ctrl_num,
					@classification_code,
					@last_modified_date,
					@modified_by,
					@stop_on_error,
					@is_valid		OUTPUT
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

	
	UPDATE 	amastcls
	SET
			classification_code = @classification_code,
			last_modified_date	= CONVERT(datetime, @last_modified_date),
			modified_by			= @modified_by
	WHERE	company_id			= @company_id
	AND		co_asset_id 		= @co_asset_id
	AND		classification_id	= @classification_id
			
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imclsupd.sp" + ", line " + STR( 130, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imClsUpd_sp] TO [public]
GO
