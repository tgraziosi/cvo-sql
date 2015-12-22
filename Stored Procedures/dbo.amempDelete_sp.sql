SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amempDelete_sp] 
( 
	@timestamp		timestamp,
	@employee_code	smEmployeeCode 
) 
AS 

DECLARE 
	@rowcount 	int, 
	@error 		int,
	@ts 		timestamp, 
	@message 	varchar(255)


DELETE 
FROM 	amemp 
WHERE 	employee_code	= @employee_code 
AND 	timestamp		= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts = timestamp 
	FROM 	amemp 
	WHERE 	employee_code = @employee_code 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 
	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amempdl.sp", 91, amemp, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	if @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amempdl.sp", 97, amemp, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amempDelete_sp] TO [public]
GO
