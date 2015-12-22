SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amChangeTrxState_sp] 
( 
	@co_trx_id			smSurrogateKey,	 	
	@old_pcn			smProcessCtrlNum,	
	@old_posting_flag	smPostingState,	 	
	@new_pcn			smProcessCtrlNum,	
	@new_posting_flag	smPostingState,	 			
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@error					smErrorCode,
	@rowcount				smCounter,
	@message				smErrorLongDesc,
	@trx_ctrl_num			smControlNumber

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amchgtrx.cpp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT 	old_pcn 			= @old_pcn, 
			old_posting_flag 	= @old_posting_flag,
			new_pcn 			= @new_pcn, 
			new_posting_flag 	= @new_posting_flag
	



IF @old_pcn is null
BEGIN
	UPDATE 	amtrxhdr
	SET		process_ctrl_num	= @new_pcn,
		posting_flag 		= @new_posting_flag
	FROM	amtrxhdr
	WHERE	co_trx_id 			= @co_trx_id
	AND	process_ctrl_num 	is null
	AND 	posting_flag 		= @old_posting_flag
END 
ELSE
BEGIN 
	UPDATE 	amtrxhdr
	SET		process_ctrl_num	= @new_pcn,
		posting_flag 		= @new_posting_flag
	FROM	amtrxhdr
	WHERE	co_trx_id 			= @co_trx_id
	AND	process_ctrl_num 	= @old_pcn
	AND 	posting_flag 		= @old_posting_flag
END 

SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0
	RETURN @error

IF @rowcount <> 1
BEGIN
	
	SELECT 	@trx_ctrl_num 	= NULL
	
	SELECT 	@trx_ctrl_num 	= trx_ctrl_num
	FROM	amtrxhdr
	WHERE 	co_trx_id 		= @co_trx_id

	IF @trx_ctrl_num IS NULL
	BEGIN
		DECLARE		@param	smErrorParam
		
		SELECT		@param = RTRIM(CONVERT(char(255), @co_trx_id))
		SELECT 		@error = 20120
		
		EXEC 		amGetErrorMessage_sp 20120, "amchgtrx.cpp", 116, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20120 @message 
	END
	ELSE   
	BEGIN
		IF @debug_level >= 5
			SELECT 	process_ctrl_num 	= process_ctrl_num, 
					posting_flag 		= posting_flag
			FROM	amtrxhdr
			WHERE	co_trx_id 			= @co_trx_id

		SELECT 		@error = 20121
		EXEC 		amGetErrorMessage_sp 20121, "amchgtrx.cpp", 128, @trx_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20121 @message 
	END

	RETURN @error
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amchgtrx.cpp" + ", line " + STR( 135, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amChangeTrxState_sp] TO [public]
GO
