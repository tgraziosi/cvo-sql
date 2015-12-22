SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE	[dbo].[amSelectTrxToPost_sp] 
(
	@company_code	smCompanyCode,				
	@trx_ctrl_num	smControlNumber,			
 
	@debug_level	smDebugLevel 	= 0			
)
AS

DECLARE	
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@rowcount			smCounter,
	@company_id			smCompanyID,
	@trx_type		 smTrxType

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amseltrx.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "


SELECT	@company_id			= company_id
FROM	glco
WHERE	company_code 		= @company_code

IF @@rowcount = 0 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20203, "tmp/amseltrx.sp", 85, @company_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20203 @message 
	RETURN 		20203 
END 

EXEC	@result = amGetTrxType_sp
					@company_id,
					@trx_ctrl_num,
					@trx_type	OUTPUT,
					@debug_level
					
IF @result <> 0
	RETURN @result
	
IF @trx_type = 50
BEGIN
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
	WHERE	company_id		= @company_id
	AND		trx_ctrl_num	= @trx_ctrl_num
	AND		posting_flag 	= 100

	SELECT	@rowcount = @@rowcount, @result = @@error
	IF @result <> 0
		RETURN @result
	
	IF @rowcount <> 1
	BEGIN
		
	 EXEC	 	amGetErrorMessage_sp 20601, "tmp/amseltrx.sp", 139, @trx_ctrl_num, @error_message = @message OUTPUT 
	 IF @message IS NOT NULL RAISERROR 	20601 @message 
		RETURN 		20601
	END
END
ELSE
BEGIN
	
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
	WHERE	company_id		= @company_id
	AND		trx_ctrl_num	= @trx_ctrl_num

	SELECT	@result = @@error
	IF @result <> 0
		RETURN @result
	

END


IF @debug_level > 3
BEGIN
	SELECT "Trx To Post"
	
	SELECT 	trx_ctrl_num
	FROM 	#amtrxhdr
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amseltrx.sp" + ", line " + STR( 193, 5 ) + " -- EXIT: "
GO
GRANT EXECUTE ON  [dbo].[amSelectTrxToPost_sp] TO [public]
GO
