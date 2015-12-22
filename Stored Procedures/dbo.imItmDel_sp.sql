SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imItmDel_sp] 
( 
	@company_id			smallint,			
	@asset_ctrl_num		char(16),				
	@sequence_id		int,					
	@stop_on_error		tinyint		= 0,	
	@debug_level		smallint	= 0		
)
AS 

DECLARE
	@result			int,			
	@is_valid		tinyint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imitmdel.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

EXEC @result = imItmVal_sp
					@action			= 1,
					@company_id	 	= @company_id,
					@asset_ctrl_num	= @asset_ctrl_num,
					@sequence_id	= @sequence_id,
					@stop_on_error	= @stop_on_error,
					@is_valid		= @is_valid		OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN

	
	DELETE	amitem
	FROM	amitem i, 
			amasset a
	WHERE	a.company_id		= @company_id
	AND	 	a.asset_ctrl_num	= @asset_ctrl_num
	AND		a.co_asset_id		= i.co_asset_id
	AND		i.sequence_id		= @sequence_id

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imitmdel.sp" + ", line " + STR( 85, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imItmDel_sp] TO [public]
GO
