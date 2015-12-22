SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imLnkDel_sp] 
( 
	@company_id			smallint,			
	@asset_ctrl_num		char(16),				
	@stop_on_error		tinyint		= 0,	
	@debug_level		smallint	= 0		
)
AS 

DECLARE
	@result				int,			
	@is_valid			tinyint			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imlnkdel.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1


EXEC @result = imLnkVal_sp
					@action 		= 1,
					@company_id		= @company_id, 
					@asset_ctrl_num	= @asset_ctrl_num, 
					@stop_on_error	= @stop_on_error,
					@is_valid		= @is_valid 	OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1 
BEGIN
	
	UPDATE	amasset
	SET		parent_id		= 0,
			linked			= 0
	FROM	amasset
	WHERE	company_id 		= @company_id
	AND		asset_ctrl_num 	= @asset_ctrl_num
	
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imlnkdel.sp" + ", line " + STR( 92, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imLnkDel_sp] TO [public]
GO
