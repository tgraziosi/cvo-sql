SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amStartDeprProcess_sp]
(
	@co_trx_id			smSurrogateKey,				
	@user_id			smUserID,					
	@company_id			smCompanyID,				
	@company_code		smCompanyCode,				
	@mark_in_use		smLogical,					
	@old_trx_state		smPostingState,				
	@new_trx_state		smPostingState,				
	@process_type		smProcessType,				
	@process_ctrl_num 	smProcessCtrlNum 	OUTPUT,	
	@debug_level		smDebugLevel		= 0		
)

AS 

DECLARE 
	@result			smErrorCode,
	@message		smErrorLongDesc,
	@rowcount		smCounter,
	@is_valid		smLogical,
	@trx_ctrl_num	smControlNumber


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrdpr.sp" + ", line " + STR( 78, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT company_code = @company_code


IF @process_type = 1
BEGIN
	SELECT	@trx_ctrl_num 	= MIN(trx_ctrl_num)
	FROM	amtrxhdr
	WHERE	posting_flag 	= 100
	AND		trx_type		= 50
		
	IF @trx_ctrl_num IS NOT NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 20125, "tmp/amstrdpr.sp", 96, @trx_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20125 @message
		RETURN 		20125
	END
END


EXEC 	@result = amCreateProcess_sp
					@user_id,
					@company_code,
					@process_type,
					@process_ctrl_num	OUTPUT,
					0
										
IF @result <> 0
	RETURN @result

IF @debug_level >= 5
	SELECT	process_ctrl_num = @process_ctrl_num



BEGIN TRANSACTION
	
	EXEC @result = pctrlupd_sp 
					@process_ctrl_num, 
					4

	IF (@result <> 0)
	BEGIN
		EXEC 		amGetErrorMessage_sp 20600, "tmp/amstrdpr.sp", 134, @process_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20600 @message
		ROLLBACK 	TRANSACTION
		RETURN 		@result
	END


	IF @mark_in_use = 1
	BEGIN
		
		EXEC @result = amMarkDepr_sp
						@company_id,
						@user_id,
						@is_valid OUTPUT
						
		SELECT @result = @@error
		IF @result <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result
		END
		
		IF @is_valid = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 20122, "tmp/amstrdpr.sp", 160, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20122 @message
			ROLLBACK 	TRANSACTION
			RETURN 		20122
		END
	END

	
	EXEC	@result = amChangeTrxState_sp
						@co_trx_id,
						NULL, 					
						@old_trx_state,
						@process_ctrl_num,
						@new_trx_state,
						@debug_level

	IF @result <> 0
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @result
	END

COMMIT TRANSACTION

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrdpr.sp" + ", line " + STR( 190, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amStartDeprProcess_sp] TO [public]
GO
