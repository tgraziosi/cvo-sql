SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imRulDel_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@effective_date			char(8),			
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@effective_date_dt		datetime,			
	@co_asset_book_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imruldel.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "


EXEC @result = imRulVal_sp
					@action				= 1,
					@company_id			= @company_id,
					@asset_ctrl_num		= @asset_ctrl_num,
					@book_code			= @book_code,
					@effective_date		= @effective_date,
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

	
	SELECT @effective_date_dt = CONVERT(datetime, @effective_date)

	
	DELETE 
	FROM	amdprhst
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		effective_date		= @effective_date_dt
		
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imruldel.sp" + ", line " + STR( 121, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imRulDel_sp] TO [public]
GO
