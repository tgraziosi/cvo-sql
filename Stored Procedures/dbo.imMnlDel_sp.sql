SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imMnlDel_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@fiscal_period_end		char(8),			
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@period_end				datetime,			
	@co_asset_book_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/immnldel.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "


EXEC @result = imMnlVal_sp
					@action				= 1,
					@company_id			= @company_id,
					@asset_ctrl_num		= @asset_ctrl_num,
					@book_code			= @book_code,
					@fiscal_period_end	= @fiscal_period_end,
					@stop_on_error		= @stop_on_error,
					@is_valid			= @is_valid		OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN
	
	SELECT	@co_asset_book_id	= co_asset_book_id
	FROM	amasset a,
			amastbk	ab
	WHERE	a.company_id		= @company_id
	AND		a.asset_ctrl_num	= @asset_ctrl_num
	AND		a.co_asset_id		= ab.co_asset_id
	AND		ab.book_code		= @book_code

	
	SELECT @period_end = CONVERT(datetime, @fiscal_period_end)

	
	DELETE 
	FROM	ammandpr
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		fiscal_period_end	= @period_end
		
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/immnldel.sp" + ", line " + STR( 121, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imMnlDel_sp] TO [public]
GO
