SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtmplasDelete_sp] 
( 
	@timestamp			timestamp,
	@company_id			smCompanyID, 
	@template_code		smTemplateCode 
) 
AS 

DECLARE @rowcount 	int,
		@error 		int,
		@ts 		timestamp, 
		@message 	varchar(255)

DELETE 
FROM 	amtmplas 
WHERE 	company_id		= @company_id 
AND 	template_code	= @template_code 
AND 	timestamp		= @timestamp 

SELECT 	@error = @@error, 
		@rowcount = @@rowcount 

IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amtmplas 
	WHERE 	company_id 		= @company_id 
	AND 	template_code 	= @template_code 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amtmasdl.sp", 90, amtmplas, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amtmasdl.sp", 96, amtmplas, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amtmplasDelete_sp] TO [public]
GO
