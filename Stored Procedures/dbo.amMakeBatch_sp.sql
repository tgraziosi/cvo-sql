SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE	[dbo].[amMakeBatch_sp] 
(
	@process_ctrl_num	smProcessCtrlNum,			
	@user_id			smUserID,					
	@company_code		smCompanyCode,				
	@major_trx_type		smTrxType,
	@debug_level		smDebugLevel	= 0			
)
AS

BEGIN

DECLARE	
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@apply_date			smApplyDate,
	@date_applied		smJulianDate,
	@batch_ctrl_num		smBatchCode,
	@trx_type			smTrxType,			 
	@batch_type			smallint		 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammkbt.sp" + ", line " + STR( 92, 5 ) + " -- ENTRY: "

	
	IF ( @@trancount > 0 )
	BEGIN
	 EXEC	 	amGetErrorMessage_sp 20610, "tmp/ammkbt.sp", 100, @error_message = @message OUTPUT 
	 IF @message IS NOT NULL RAISERROR 	20610 @message 
		RETURN 		20610
	END
	
	
	IF NOT EXISTS(	SELECT	company_code
					FROM	glcomp_vw
					WHERE	company_code = @company_code )
			
	BEGIN
	 EXEC	 	amGetErrorMessage_sp 20611, "tmp/ammkbt.sp", 113, @company_code, @error_message = @message OUTPUT 
	 IF @message IS NOT NULL RAISERROR 	20611 @message 
		RETURN 		20611
	END



	
	
	SELECT	@apply_date 	= apply_date,
			@trx_type		= trx_type
	FROM	#amtrxhdr


	SELECT 	@date_applied 	= DATEDIFF(dd, "1/1/1980", @apply_date) + 722815,
			@batch_type		= 10000 + @trx_type 

	
	
	EXEC @result = amGetNextBatchCode_sp
 				@batch_type,				
 					@user_id,							 
 	 		@date_applied,					
					@company_code,				 
			 		@batch_ctrl_num	 OUTPUT,	
					@debug_level


		
	IF @debug_level >= 3
	BEGIN
		SELECT 	CONVERT(char(20), "Apply Date") + CONVERT(char(20), "Trx Type") + 
					 CONVERT(char(20), "Batch Ctrl Num")
		
		SELECT 	CONVERT(char(20), @apply_date) + CONVERT(char(20), @trx_type) + 
					 CONVERT(char(20), @batch_ctrl_num)
	END	

	
	UPDATE	#amtrxhdr
	SET		batch_ctrl_num 		= @batch_ctrl_num

	SELECT @result = @@error
	IF ( @result != 0 )
		RETURN @result

	
	UPDATE	batchctl
	SET		process_group_num 	= @process_ctrl_num,
	 	posted_flag 		= -1
	WHERE	batch_ctrl_num 		= @batch_ctrl_num

	SELECT @result = @@error
	IF ( @result != 0 )
		RETURN @result

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammkbt.sp" + ", line " + STR( 184, 5 ) + " -- EXIT: "

	RETURN 0
	
END
GO
GRANT EXECUTE ON  [dbo].[amMakeBatch_sp] TO [public]
GO
