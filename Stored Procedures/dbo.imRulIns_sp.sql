SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imRulIns_sp] 
( 
	@company_id				smallint,				
	@asset_ctrl_num			char(16),					
	@book_code				char(8),				
	@effective_date			char(8),				
	@last_modified_date		char(8) 	= NULL,		
	@modified_by			int 		= 1,		
	@depr_rule_code			char(8), 				
	@salvage_value			float		= 0,		
	@stop_on_error			tinyint		= 0,		
	@debug_level			smallint	= 0			
)
AS 

DECLARE										
	@result					int,					
	@is_valid				tinyint,				
	@effective_date_dt		datetime,				
	@co_asset_book_id		int						

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imrulins.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "


IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)


EXEC @result = imRulVal_sp
					@action				= 0,
					@company_id			= @company_id,
					@asset_ctrl_num		= @asset_ctrl_num,
					@book_code			= @book_code,
					@effective_date		= @effective_date,
					@last_modified_date	= @last_modified_date,
					@modified_by		= @modified_by,
					@depr_rule_code		= @depr_rule_code,
					@salvage_value		= @salvage_value,
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

	
	INSERT INTO amdprhst
	(
		co_asset_book_id,
		effective_date,
		last_modified_date,
		modified_by,
		posting_flag,
		depr_rule_code,
		limit_rule_code,
		salvage_value,
		catch_up_diff,
		end_life_date,
		switch_to_sl_date
	)
	VALUES
	(	
		@co_asset_book_id,
		@effective_date,
		@last_modified_date,
		@modified_by,
		0,					
		@depr_rule_code,
		"",
		@salvage_value,
		0,					
		NULL,				
		NULL				
	)
		
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imrulins.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imRulIns_sp] TO [public]
GO
