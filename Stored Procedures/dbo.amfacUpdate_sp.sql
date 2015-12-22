SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amfacUpdate_sp] 
( 
	@timestamp 				timestamp,
	@company_id				smCompanyID, 
	@fac_mask				smAccountCode, 
	@fac_mask_description	smStdDescription, 
	@last_modified_date		smISODate, 
	@modified_by 			smUserID 
) 
AS 

DECLARE 
	@ts 		timestamp, 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@message 	smErrorLongDesc


UPDATE amfac 
SET 
		fac_mask_description		= @fac_mask_description,
		last_modified_date = @last_modified_date,
		modified_by					= @modified_by 
WHERE 	company_id 	= @company_id 
AND 	fac_mask					= @fac_mask
AND		timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 

IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 			= timestamp 
	FROM 	amfac 
	WHERE 	company_id		= @company_id
	AND		fac_mask		= @fac_mask
	 
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amfacup.sp", 92, amfac, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amfacup.sp", 99, amfac, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amfacUpdate_sp] TO [public]
GO
