SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imAstDel_sp] 
( 
	@company_id			smallint,			
	@asset_ctrl_num		char(16),				
	@stop_on_error		tinyint		= 0,	
	@debug_level		smallint	= 0		
)
AS 

DECLARE
	@message		varchar(255),	
	@result			int,			
	@is_valid		tinyint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imastdel.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

EXEC @result = imAstVal_sp
					@action			= 1,
					@company_id	 	= @company_id,
					@asset_ctrl_num	= @asset_ctrl_num,
					@stop_on_error	= @stop_on_error,
					@is_valid		= @is_valid		OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN

	
	DELETE
	FROM	amasset
	WHERE	company_id		= @company_id
	AND	 	asset_ctrl_num	= @asset_ctrl_num

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

	
	IF @debug_level < 100
		EXEC 		amGetErrorMessage_sp 
						20405, "tmp/imastdel.sp", 86, 
						@asset_ctrl_num, 
						@error_message = @message OUT 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imastdel.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imAstDel_sp] TO [public]
GO
