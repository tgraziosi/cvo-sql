SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imPrfIns_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@fiscal_period_end		char(8),			
	@current_cost			float 		= 0, 	
	@accum_depr				float		= 0,	
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@fiscal_period_end_dt	datetime,			
	@co_asset_book_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprfins.sp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "


EXEC @result = imPrfVal_sp
					0,
					@company_id,
					@asset_ctrl_num,
					@book_code,
					@fiscal_period_end,
					@current_cost,
					@accum_depr,
					@stop_on_error,
					@is_valid		OUTPUT
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

	
	SELECT @fiscal_period_end_dt = CONVERT(datetime, @fiscal_period_end)

	
	INSERT INTO amastprf
	(
		co_asset_book_id,
		fiscal_period_end,
		current_cost,
		accum_depr,
		effective_date
	)
	VALUES
	(
		@co_asset_book_id,
		@fiscal_period_end,
		@current_cost,
		- @accum_depr, 	
		NULL
	)
	
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprfins.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imPrfIns_sp] TO [public]
GO
