SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amRecoverPosting_sp]
(
	@user_id				smUserID,					
	@company_code			smCompanyCode,				
	@old_process_ctrl_num	smProcessCtrlNum,			
	@debug_level			smDebugLevel 		= 0		
)
AS 

DECLARE 
	@result					smErrorCode,
	@message				smErrorLongDesc,
	@rowcount				smCounter ,
	@new_process_ctrl_num 	smProcessCtrlNum 	,	
	
	@posting_complete		smLogical,				
	@posting_flag			int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecpst.sp" + ", line " + STR( 79, 5 ) + " -- ENTRY: "

INSERT INTO #amtrxhdr
(
	co_trx_id, 
	trx_ctrl_num, 
	trx_description,
	doc_reference,
	journal_ctrl_num,
	batch_ctrl_num,
	apply_date, 
	trx_type, 
	last_modified_date
)
SELECT
	co_trx_id, 
	trx_ctrl_num, 
	trx_description,
	doc_reference,
	"",					
	NULL,
	apply_date, 
	trx_type, 
	last_modified_date
FROM	amtrxhdr
WHERE	process_ctrl_num 	= @old_process_ctrl_num
AND		posting_flag		= -1	 

SELECT	@rowcount 	= @@rowcount, 
		@result 	= @@error
IF @result <> 0
	RETURN @result
		
IF @rowcount = 0
BEGIN		
	SELECT	@new_process_ctrl_num	= "",
		 
			@posting_complete 		= 1
	IF @debug_level >= 3	
		SELECT "posting_complete = TRUE, no rows with @old_process_ctrl_num and TS_INUSE (-1)" + @old_process_ctrl_num

	SELECT @posting_flag = posting_flag
	FROM	amtrxhdr
	WHERE	process_ctrl_num 	= @old_process_ctrl_num

	IF @posting_flag = 1
	
		SELECT @posting_complete = 1 
	ELSE
	BEGIN
		SELECT @posting_complete = 100
		IF @debug_level >= 3	
			SELECT "There is an inconsistency in the tables: the process in table is incomplete but the transaction is not TS_INUSE" + @old_process_ctrl_num
	END
END
ELSE
BEGIN

	SELECT	@posting_complete = 0

	
 

	

	BEGIN TRANSACTION

		
		EXEC 	@result = amCreateProcess_sp
							@user_id,
							@company_code,
							0,
							@new_process_ctrl_num	OUTPUT,
							@debug_level
								
		IF @result <> 0
		BEGIN
			ROLLBACK 	TRANSACTION	
			RETURN @result
		END

		IF @debug_level >= 3
			SELECT	"New Process Ctrl Num = " + @new_process_ctrl_num

		
		UPDATE 	amtrxhdr
		SET 	process_ctrl_num	= @new_process_ctrl_num
		FROM 	#amtrxhdr 	tmp, 
				amtrxhdr 	th
		WHERE 	tmp.co_trx_id 		= th.co_trx_id	 
		AND		process_ctrl_num 	= @old_process_ctrl_num

		IF @debug_level >= 3
			SELECT "Updated amtrxhdr with new_process_ctrl_num=" + @new_process_ctrl_num 

		SELECT @result = @@error, @rowcount = @@rowcount
		IF (@result <> 0) OR (@rowcount = 0)
		BEGIN
			IF @debug_level >= 3
				IF @rowcount = 0
					SELECT "Update amtrxhdr did not have rows, marking new_process_ctrl_num as complete"
			
			
	
			IF @rowcount = 0
			BEGIN
				EXEC 		amGetErrorMessage_sp ERR_ERR_PROCESS_IN_USE, "tmp/amrecpst.sp", 204, @old_process_ctrl_num, @error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20614 @message		
				SELECT @result = 20614
			END

			ROLLBACK TRANSACTION
			RETURN @result
		END

 	 	
		EXEC @result = pctrlupd_sp 
						@new_process_ctrl_num, 
						4

		IF (@result <> 0)
		BEGIN
			EXEC 		amGetErrorMessage_sp 20600, "tmp/amrecpst.sp", 223, @new_process_ctrl_num, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20600 @message
			ROLLBACK 	TRANSACTION
			RETURN 		@result
		END

		IF @debug_level >= 3
			SELECT "Updated new_process_ctrl_num to be in running state " + @new_process_ctrl_num 
	 
		
		EXEC @result = pctrlupd_sp 
						@old_process_ctrl_num, 
						3

		IF (@result <> 0)
		BEGIN
			EXEC 		amGetErrorMessage_sp 20600, "tmp/amrecpst.sp", 242, @old_process_ctrl_num, @error_message = @message OUT
			IF @message IS NOT NULL RAISERROR 	20600 @message
			ROLLBACK 	TRANSACTION
			RETURN 		@result
		END
		IF @debug_level >= 3
			SELECT "Updated old_process_ctrl_num to be in completed state " + @old_process_ctrl_num 


	COMMIT TRANSACTION
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecpst.sp" + ", line " + STR( 254, 5 ) + " -- EXIT: "

RETURN 	@posting_complete
GO
GRANT EXECUTE ON  [dbo].[amRecoverPosting_sp] TO [public]
GO
