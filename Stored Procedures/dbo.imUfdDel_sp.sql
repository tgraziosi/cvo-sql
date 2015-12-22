SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imUfdDel_sp] 
( 
	@company_id			smallint,			
	@asset_ctrl_num		char(16),				
	@stop_on_error		tinyint		= 0,	
	@debug_level		smallint	= 0		
)
AS 

DECLARE
	@is_valid			tinyint,
	@result				int,				
	@user_field_id		int,				
	@rowcount			int,				
	@message			varchar(255)		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imufddel.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "


EXEC	@result = imUfdVal_sp
					@action 		= 1,
					@company_id 	= @company_id,
					@asset_ctrl_num	= @asset_ctrl_num,
					@stop_on_error	= @stop_on_error,
					@is_valid		= @is_valid	OUTPUT
IF @is_valid = 1
BEGIN
	SELECT	@user_field_id	= NULL
	
	SELECT	@user_field_id 	= user_field_id
	FROM	amasset
	WHERE	company_id 		= @company_id
	AND		asset_ctrl_num	= @asset_ctrl_num

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

	IF @user_field_id IS NULL
	BEGIN
		
		EXEC 		amGetErrorMessage_sp 21251, "tmp/imufddel.sp", 93, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21251 @message 
	END
	ELSE
	BEGIN
		IF @user_field_id != 0
		BEGIN
			
			UPDATE	amusrfld
			SET		user_code_1		= "",
					user_code_2		= "",
					user_code_3		= "",
					user_code_4		= "",
					user_date_1		= NULL,
					user_date_2		= NULL,
					user_date_3		= NULL,
					user_date_4		= NULL,
					user_amount_1	= 0,
					user_amount_2	= 0,
					user_amount_3	= 0,
					user_amount_4	= 0
			WHERE	user_field_id	= @user_field_id
			
			SELECT @result = @@error, @rowcount = @@rowcount
			IF @result <> 0
				RETURN @result
		END
	END
END
					
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imufddel.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imUfdDel_sp] TO [public]
GO
