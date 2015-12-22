SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imMnlIns_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@fiscal_period_end		char(8),			
	@last_modified_date		char(8) 	= NULL,	
	@modified_by			int 		= 1,	
	@depr_expense			float 		= 0, 	
	@stop_on_error			tinyint		= 0, 	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint,			
	@period_end				datetime,			
	@co_asset_book_id		int					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/immnlins.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "


IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)


EXEC @result = imMnlVal_sp
					0,
					@company_id,
					@asset_ctrl_num,
					@book_code,
					@fiscal_period_end,
					@last_modified_date,
					@modified_by,
					@depr_expense,
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

	
	SELECT @period_end = CONVERT(datetime, @fiscal_period_end)

	
	INSERT INTO ammandpr
	(
		co_asset_book_id,
		fiscal_period_end,
		last_modified_date,
		modified_by,
		posting_flag,
		depr_expense
	)
	VALUES
	(	
		@co_asset_book_id,
		@period_end,
		@last_modified_date,
		@modified_by,
		0,					
		@depr_expense
	)
		
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/immnlins.sp" + ", line " + STR( 147, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imMnlIns_sp] TO [public]
GO
