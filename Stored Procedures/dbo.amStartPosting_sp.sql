SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amStartPosting_sp]
(
	@user_id			smUserID,					
	@company_code		smCompanyCode,				
	@trx_type			smTrxType,					
 
	@debug_level		smDebugLevel 	= 0			
)
AS 

DECLARE 
	@result			smErrorCode,
	@message		smErrorLongDesc,
	@num_trxs		smCounter,
	@rowcount		smCounter,
	@trx_ctrl_num	smControlNumber,
	@process_ctrl_num 	smProcessCtrlNum

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrpst.sp" + ", line " + STR( 101, 5 ) + " -- ENTRY: "

IF @trx_type = 50
BEGIN
	
	EXEC 	@result = amCreateProcess_sp
						@user_id,
						@company_code,
						0,
						@process_ctrl_num	OUTPUT,
						@debug_level
						
	IF @result <> 0
		RETURN @result

	IF @debug_level >= 3
		SELECT	"process_ctrl_num = " + @process_ctrl_num

	
	SELECT	@num_trxs = COUNT(co_trx_id)
	FROM	#amtrxhdr

	IF @debug_level >= 3
		SELECT	"Num Transactions to Post = " + CONVERT(char(20), @num_trxs)

	

	BEGIN TRANSACTION
		
		EXEC @result = pctrlupd_sp 
						@process_ctrl_num, 
						4

		IF (@result <> 0)
		BEGIN
			EXEC 		amGetErrorMessage_sp 20600, "tmp/amstrpst.sp", 149, @process_ctrl_num, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20600 @message
			ROLLBACK 	TRANSACTION
			RETURN 		@result
		END


		
		UPDATE 	amtrxhdr
		SET 	posting_flag 		= -1,
				process_ctrl_num	= @process_ctrl_num
		FROM 	#amtrxhdr 	tmp, 
				amtrxhdr 	th
		WHERE 	tmp.co_trx_id 		= th.co_trx_id	 
		AND		th.posting_flag 	= 100

		SELECT @result = @@error, @rowcount = @@rowcount
		IF @result <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result
		END

		IF @num_trxs <> @rowcount
		BEGIN
			
			SELECT @trx_ctrl_num = NULL
			SET ROWCOUNT 1
			
			SELECT 	@trx_ctrl_num 		= tmp.trx_ctrl_num
			FROM 	#amtrxhdr 	tmp, 
					amtrxhdr 	th
			WHERE 	tmp.co_trx_id 		= th.co_trx_id	 
			AND		th.posting_flag 	<> 100

			SET ROWCOUNT 0

			IF @trx_ctrl_num IS NULL
			BEGIN
				
				EXEC 		amGetErrorMessage_sp 20603, "tmp/amstrpst.sp", 204, @error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20603 @message
				ROLLBACK 	TRANSACTION
				RETURN 		20603
			END
			ELSE
			BEGIN
				EXEC 		amGetErrorMessage_sp 20601, "tmp/amstrpst.sp", 211, @trx_ctrl_num, @error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20601 @message
				ROLLBACK 	TRANSACTION
				RETURN 		20601
			END
		END

	COMMIT TRANSACTION
END
ELSE
BEGIN
	
	
	
	SELECT	@process_ctrl_num	= process_ctrl_num
	FROM	#amtrxhdr tmp,
			amtrxhdr th
	WHERE	th.co_trx_id 		= tmp.co_trx_id

	IF @process_ctrl_num IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 20124, "tmp/amstrpst.sp", 240, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20124 @message
		RETURN 		20124
	END

	BEGIN TRANSACTION
		
		EXEC	@result = pctrlchg_sp	
							@process_ctrl_num,
							0		 


		IF @result <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result
		END
		
		
		UPDATE 	amtrxhdr
		SET 	posting_flag 		= -1
		FROM 	#amtrxhdr 	tmp, 
				amtrxhdr 	th
		WHERE 	tmp.co_trx_id 		= th.co_trx_id	 
		AND 	th.process_ctrl_num	= @process_ctrl_num

		SELECT @result = @@error
		IF @result <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN @result
		END

	COMMIT TRANSACTION
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrpst.sp" + ", line " + STR( 282, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amStartPosting_sp] TO [public]
GO
