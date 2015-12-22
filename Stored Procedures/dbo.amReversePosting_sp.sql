SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amReversePosting_sp]
(
	@trx_type			smTrxType,					
	@debug_level		smDebugLevel 	= 0			
)
AS 

DECLARE 
	@result			smErrorCode,
	@message		smErrorLongDesc,
	@num_trxs		smCounter,
	@rowcount		smCounter,
	@trx_ctrl_num	smControlNumber

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrevpst.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

IF @trx_type = 50
BEGIN
	
	SELECT	@num_trxs = COUNT(co_trx_id)
	FROM	#amtrxhdr

	IF @debug_level >= 3
		SELECT	"Num Transactions to recover (backwards) from posting on = " + CONVERT(char(20), @num_trxs)

	
	UPDATE 	amtrxhdr
	SET 	posting_flag 		= 100,
			process_ctrl_num	= NULL
	FROM 	#amtrxhdr 	tmp, 
			amtrxhdr 	th
	WHERE 	tmp.co_trx_id 		= th.co_trx_id	 
	AND		th.posting_flag 	= -1

	SELECT @result = @@error, @rowcount = @@rowcount
	IF @result <> 0
		RETURN @result

	IF @num_trxs <> @rowcount
	BEGIN
		
		SELECT @trx_ctrl_num = NULL
		SET ROWCOUNT 1
		
		SELECT 	@trx_ctrl_num 		= tmp.trx_ctrl_num
		FROM 	#amtrxhdr 	tmp, 
				amtrxhdr 	th
		WHERE 	tmp.co_trx_id 		= th.co_trx_id	 
		AND		th.posting_flag 	<> -1

		SET ROWCOUNT 0

		IF @trx_ctrl_num IS NULL
		BEGIN
			
			EXEC 		amGetErrorMessage_sp 20603, "tmp/amrevpst.sp", 127, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20603 @message
			RETURN 		20603
		END
		ELSE
		BEGIN
			EXEC 		amGetErrorMessage_sp 20607, "tmp/amrevpst.sp", 133, @trx_ctrl_num, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20607 @message
			RETURN 		20607
		END
	END
END
ELSE
BEGIN
	
	EXEC 		amGetErrorMessage_sp 20612, "tmp/amrevpst.sp", 146, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20612 @message
	RETURN 		20612
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrevpst.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amReversePosting_sp] TO [public]
GO
