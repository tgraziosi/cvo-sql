SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetTrxToRecover_sp] 
( 
	@process_ctrl_num		smProcessCtrlNum,		
	@co_trx_id				smSurrogateKey 	OUTPUT,	
	@trx_ctrl_num			smControlNumber OUTPUT,	
	@debug_level			smDebugLevel = 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amtxtorc.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

DECLARE	@result 	smErrorCode,
		@message	smErrorLongDesc

SELECT	@co_trx_id			= NULL

SELECT	@co_trx_id			= co_trx_id,
		@trx_ctrl_num		= trx_ctrl_num
FROM	amtrxhdr
WHERE	process_ctrl_num	= @process_ctrl_num

IF (@co_trx_id IS NULL)
BEGIN
	EXEC 		amGetErrorMessage_sp 20613, "tmp/amtxtorc.sp", 71, @process_ctrl_num, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20613 @message

	
	EXEC @result = pctrlupd_sp 
					@process_ctrl_num, 
					3

	IF (@result <> 0)
	BEGIN
		EXEC 		amGetErrorMessage_sp 20600, "tmp/amtxtorc.sp", 84, @process_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20600 @message
		RETURN 		20600
	END

	RETURN	20613
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amtxtorc.sp" + ", line " + STR( 92, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetTrxToRecover_sp] TO [public]
GO
