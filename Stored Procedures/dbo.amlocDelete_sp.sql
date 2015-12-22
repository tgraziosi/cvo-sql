SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amlocDelete_sp] 
( 
	@timestamp 	timestamp,
	@location_code 	smLocationCode 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)


DELETE 
FROM 	amloc 
WHERE 	location_code 	= @location_code 
and 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amloc 
	WHERE 	location_code 	= @location_code 
	
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 
	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amlocdl.sp", 92, amloc, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amlocdl.sp", 98, amloc, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amlocDelete_sp] TO [public]
GO
