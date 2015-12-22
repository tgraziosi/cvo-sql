SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtrxdefDelete_sp] 
( 
	@timestamp timestamp,
 	@trx_name smName 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)


DELETE 
FROM 	amtrxdef 
WHERE 	trx_name	= @trx_name 
AND 	timestamp		= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts = timestamp 
	FROM 	amtrxdef 
	WHERE 	trx_name = @trx_name 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC	 	amGetErrorMessage_sp 20002, "tmp/amtdfdl.sp", 80, amtrxdef, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amtdfdl.sp", 86, amtrxdef, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefDelete_sp] TO [public]
GO
