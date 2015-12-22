SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amvchr_vwDelete_sp] 
( 
	@timestamp		timestamp,
	@trx_ctrl_num	smControlNumber
) 
AS 

DECLARE 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@ts 		timestamp, 
	@message 	smErrorLongDesc

DELETE 	amapnew	
WHERE 	trx_ctrl_num 	= @trx_ctrl_num
AND		timestamp		= @timestamp

SELECT @error = @@error, @rowcount = @@rowcount 

IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amapnew
	WHERE 	trx_ctrl_num 	= @trx_ctrl_num
		
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amvchrdl.sp", 81, comments, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amvchrdl.sp", 88, comments, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amvchr_vwDelete_sp] TO [public]
GO
