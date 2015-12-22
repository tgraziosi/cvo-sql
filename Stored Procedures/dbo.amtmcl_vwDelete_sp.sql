SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtmcl_vwDelete_sp]
(
	@timestamp 	timestamp,
	@company_id 	smCompanyID,
	@template_code 	smTemplateCode,
	@classification_id 	smSurrogateKey,
	@last_modified_date				varchar(30),
	@modified_by					smUserID
) 
AS

DECLARE @rowcount 					int,
	 	@error 						int,
		@ts 						timestamp,
		@message 					varchar(255),
		@modified_date				smApplyDate

SELECT	@modified_date	= CONVERT(datetime, @last_modified_date, 112)


DELETE 
FROM 	amtmplcl 
WHERE	template_code = @template_code 
AND		company_id = @company_id 
AND		classification_id = @classification_id 
AND		timestamp = @timestamp

SELECT @error = @@error, @rowcount = @@rowcount

IF @error <> 0 
	RETURN @error

ELSE 
BEGIN
	IF @rowcount = 0 
	BEGIN
		
		SELECT 	@ts 				= timestamp 
		FROM 	amtmplcl 
		WHERE	template_code 		= @template_code 
		AND		company_id 			= @company_id 
		AND		classification_id 	= @classification_id

		SELECT @error = @@error, @rowcount = @@rowcount
		IF @error <> 0 
			RETURN @error

		IF @rowcount = 0 
		BEGIN
			EXEC	 	amGetErrorMessage_sp 20002, "tmp/amtmcldl.sp", 97, amtmplcl, @error_message = @message out
			IF @message IS NOT NULL RAISERROR 	20002 @message
			RETURN 		20002
		END
		IF @ts <> @timestamp
		BEGIN
			EXEC	 	amGetErrorMessage_sp 20001, "tmp/amtmcldl.sp", 103, amtmplcl, @error_message = @message out
			IF @message IS NOT NULL RAISERROR 	20001 @message
			RETURN 		20001
		END
	END
END


RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amtmcl_vwDelete_sp] TO [public]
GO
