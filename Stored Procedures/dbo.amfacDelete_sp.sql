SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amfacDelete_sp] 
( 
	@timestamp			timestamp,
	@company_id			smCompanyID,
	@fac_mask			smAccountCode 
) 
AS 

DECLARE 
	@ts 		timestamp, 
	@rowcount 	smCounter, 
	@error 		smErrorCode, 
	@message 	smErrorLongDesc


DELETE 
FROM 	amfac 
WHERE 	company_id 		= @company_id 
AND 	fac_mask 	= @fac_mask 
AND 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0 
	RETURN @error
	 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amfac 
	WHERE 	company_id 		= @company_id 
	AND 	fac_mask 	= @fac_mask 
	
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0 
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amfacdl.sp", 84, amfac, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amfacdl.sp", 91, amfac, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	END 
END 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amfacDelete_sp] TO [public]
GO
