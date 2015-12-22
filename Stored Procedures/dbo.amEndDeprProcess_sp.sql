SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amEndDeprProcess_sp]
(
	@company_id				smCompanyID,			
	@co_trx_id				smSurrogateKey,			
	@mark_in_use			smLogical,			 	
	@old_trx_state			smPostingState,			
	@new_trx_state			smPostingState,			
	@old_process_ctrl_num 	smProcessCtrlNum, 		
	@new_process_ctrl_num 	smProcessCtrlNum = NULL,
	@debug_level			smDebugLevel	 = 0	
)
AS 

DECLARE 
	@result			smErrorCode,
	@message		smErrorLongDesc,
	@is_valid		smLogical

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amenddpr.sp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "



BEGIN TRANSACTION

	
	EXEC	@result = amChangeTrxState_sp
						@co_trx_id,
						@old_process_ctrl_num,
						@old_trx_state,
						@new_process_ctrl_num,
						@new_trx_state,
						@debug_level 	= @debug_level
						
	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @result
	END

	IF @mark_in_use = 1
	BEGIN
		
		EXEC @result = amMarkDepr_sp
						@company_id,
						0,				
						@is_valid OUTPUT,
						@debug_level 	= @debug_level
						
		SELECT @result = @@error
		IF @result <> 0 		
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result
		END
		
		IF @is_valid = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 20123, "tmp/amenddpr.sp", 121, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20123 @message
			ROLLBACK 	TRANSACTION
			RETURN 		20123
		END
	END
	
	EXEC @result = pctrlupd_sp 
					@old_process_ctrl_num, 
					3

	IF (@result <> 0)
	BEGIN
		EXEC 		amGetErrorMessage_sp 20600, "tmp/amenddpr.sp", 137, @old_process_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20600 @message
		ROLLBACK 	TRANSACTION
		RETURN 		20600
	END


	
	IF ( @old_trx_state = -102 )
	BEGIN
		DELETE amtrxast
		FROM amtrxast att
		WHERE att.co_trx_id = @co_trx_id
	
	 SELECT @result = @@error 
		IF (@result != 0)
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result
		END 
	END

COMMIT TRANSACTION

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amenddpr.sp" + ", line " + STR( 161, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amEndDeprProcess_sp] TO [public]
GO
