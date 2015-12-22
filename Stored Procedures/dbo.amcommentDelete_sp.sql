SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amcommentDelete_sp] 
( 
	@timestamp		timestamp,
	@company_id		smCompanyID, 
	@key_type		smallint,
	@key_1			varchar(32),
	@sequence_id	int

) 
AS 

DECLARE 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@ts 		timestamp, 
	@message 	smErrorLongDesc

DELETE 	comments
FROM
	comments 	a,
	glco	 	co

WHERE 	a.company_code 	= co.company_code
AND		co.company_id	= @company_id
AND		a.key_type		= @key_type
AND		a.key_1			= @key_1
AND 	a.sequence_id 	= @sequence_id 
AND		a.timestamp		= @timestamp

SELECT @error = @@error, @rowcount = @@rowcount 

IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 		= a.timestamp 
	FROM
		comments 	a,
		glusers_vw 	u,
		glco	 	co

	WHERE 	a.company_code 	= co.company_code
	AND		co.company_id	= @company_id
	AND		u.user_id	 	= a.updated_by
	AND		a.key_type		= @key_type
	AND		a.key_1			= @key_1 
	AND		a.sequence_id 	= @sequence_id 
	
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amcommdl.sp", 103, comments, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amcommdl.sp", 110, comments, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amcommentDelete_sp] TO [public]
GO
