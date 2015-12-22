SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amstatusDelete_sp] 
( 
	@timestamp		timestamp,
	@status_code	smStatusCode 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)


DELETE 
FROM 	amstatus 
WHERE	status_code	= @status_code 
AND 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT @ts = timestamp from amstatus where 
		status_code = @status_code 
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 
	IF @rowcount = 0  
	BEGIN 
		EXEC		amGetErrorMessage_sp 20002, "tmp/amstatdl.sp", 90, amstatus, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC	 	amGetErrorMessage_sp 20001, "tmp/amstatdl.sp", 96, amstatus, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusDelete_sp] TO [public]
GO
