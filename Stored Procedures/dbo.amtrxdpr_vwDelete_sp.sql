SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtrxdpr_vwDelete_sp] 
( 
	@timestamp			timestamp,
	@company_id			smCompanyID, 
	@trx_ctrl_num		smControlNumber 
) 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@error 		smErrorCode, 
	@ts 		timestamp, 
	@message 	smErrorLongDesc


DELETE 
FROM 	amtrxhdr 
WHERE 	company_id 	= @company_id 
AND 	trx_ctrl_num 	= @trx_ctrl_num 
AND 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amtrxhdr 
	WHERE 	company_id 		= @company_id 
	AND 	trx_ctrl_num 	= @trx_ctrl_num 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amtrdpdl.sp", 104, amtrxhdr, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amtrdpdl.sp", 111, amtrxhdr, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amtrxdpr_vwDelete_sp] TO [public]
GO
