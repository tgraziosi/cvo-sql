SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imABkUpd_sp] 
( 
	@company_id				smallint,			
	@asset_ctrl_num			char(16),				
	@book_code				char(8),			
	@placed_in_service_date	char(8)		= NULL,	
	@stop_on_error			tinyint		= 0,	
	@debug_level			smallint	= 0		
)
AS 

DECLARE
	@result					int,				
	@is_valid				tinyint				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imabkupd.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "


EXEC @result = imABkVal_sp
					2,
					@company_id,
					@asset_ctrl_num,
					@book_code,
					@placed_in_service_date,
					@stop_on_error,
					@is_valid		OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN
	
	UPDATE	amastbk
	SET		placed_in_service_date	= @placed_in_service_date
	FROM	amasset a,
			amastbk	ab
	WHERE	a.company_id		= @company_id
	AND		a.asset_ctrl_num	= @asset_ctrl_num
	AND		a.co_asset_id		= ab.co_asset_id
	AND		ab.book_code		= @book_code
		
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imabkupd.sp" + ", line " + STR( 101, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imABkUpd_sp] TO [public]
GO
