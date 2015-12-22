SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imLnkUpd_sp] 
( 
	@company_id			smallint,			
	@asset_ctrl_num		char(16),				
	@parent_ctrl_num	char(16),				
	@stop_on_error		tinyint		= 0,	
	@debug_level		smallint	= 0		
)
AS 

DECLARE
	@result				int,			
	@is_valid			tinyint,		
	@parent_id			int,			
	@link_type			tinyint			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imlnkupd.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

SELECT 	@is_valid = 1


EXEC @result = imLnkVal_sp
					@action 			= 2,
					@company_id			= @company_id, 
					@asset_ctrl_num 	= @asset_ctrl_num, 
					@parent_ctrl_num	= @parent_ctrl_num,
					@stop_on_error		= @stop_on_error,
					@is_valid			= @is_valid 	OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1 
BEGIN
	
	SELECT 	@link_type		= linked,
			@parent_id 		= co_asset_id
	FROM	amasset
	WHERE	company_id 		= @company_id
	AND		asset_ctrl_num 	= @parent_ctrl_num

	
	UPDATE	amasset
	SET		parent_id		= @parent_id
	FROM	amasset
	WHERE	company_id 		= @company_id
	AND		asset_ctrl_num 	= @asset_ctrl_num
	
	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

	IF @link_type <> 1
	BEGIN
		
		UPDATE	amasset
		SET		linked			= 1
		FROM	amasset
		WHERE	co_asset_id 	= @parent_id
		
		SELECT @result = @@error
		IF @result <> 0
			RETURN @result
	END

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imlnkupd.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imLnkUpd_sp] TO [public]
GO
