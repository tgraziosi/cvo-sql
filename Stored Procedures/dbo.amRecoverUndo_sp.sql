SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amRecoverUndo_sp] 
( 
	@process_ctrl_num	 	smProcessCtrlNum,		
	@company_id				smCompanyID,			
	@trx_ctrl_num			smControlNumber OUTPUT,	
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@co_trx_id 				smSurrogateKey,
	@result					smErrorCode,
	@message				smErrorLongDesc


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecund.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT	pcn = @process_ctrl_num


SELECT dummy_select = 1


EXEC @result = amGetTrxToRecover_sp 
				@process_ctrl_num,		
				@co_trx_id 		OUTPUT,
				@trx_ctrl_num	OUTPUT,
				@debug_level

IF @result = 20613
	RETURN 0

IF @result <> 0
	RETURN @result


EXEC @result = pctrlchg_sp
					@process_ctrl_num

IF (@result <> 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 20600, "tmp/amrecund.sp", 104, @process_ctrl_num, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20600 @message
	RETURN 		20600
END



EXEC @result = amUndoDeprTrx_sp
					@co_trx_id,
					@debug_level
IF @result <> 0
BEGIN
	

	RETURN @result
END


EXEC @result = amEndDeprProcess_sp
					@company_id,
					@co_trx_id,
					1,
					-101,
					0,
					@process_ctrl_num,
					@debug_level = @debug_level
IF @result <> 0
	RETURN @result

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecund.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amRecoverUndo_sp] TO [public]
GO
