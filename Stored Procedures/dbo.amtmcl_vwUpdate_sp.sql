SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtmcl_vwUpdate_sp]
(
	@timestamp 	timestamp,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@template_code 	smTemplateCode,
	@classification_code 	smClassificationCode,
	@classification_description		smStdDescription,		
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) 
AS

DECLARE @rowcount 	int
DECLARE @error 		int
DECLARE @ts 		timestamp
DECLARE @message 	varchar(255)

IF 	(@timestamp IS NULL)
OR 	(@timestamp = 0)
BEGIN
	IF ( LTRIM(@classification_code) IS NOT NULL AND LTRIM(@classification_code) != " " )
	BEGIN
		
		EXEC @error = amtmcl_vwInsert_sp
						@company_id,
						@classification_id,
						@template_code,
						@classification_code,
						@classification_description,		
						@last_modified_date,
						@modified_by 
		RETURN @error
	END
	
END
ELSE 
BEGIN
	IF ( LTRIM(@classification_code) IS NOT NULL AND LTRIM(@classification_code) != " " )
	BEGIN
		UPDATE amtmplcl 
		SET
			classification_code 	=	@classification_code,
			last_modified_date 	=	@last_modified_date,
			modified_by 	=	@modified_by
		WHERE
				template_code =	@template_code 
		AND		company_id 	=	@company_id 
		AND		classification_id 	=	@classification_id 
		AND		timestamp 	=	@timestamp
		
		SELECT @error = @@error, @rowcount = @@rowcount
		IF @error <> 0 
			RETURN @error
		
		IF @rowcount = 0 
		BEGIN
			
			SELECT 	@ts 				= timestamp 
			FROM 	amtmplcl 
			WHERE	template_code 		= @template_code 
			AND	 	company_id 			= @company_id 
			AND	 	classification_id 	= @classification_id

			SELECT @error = @@error, @rowcount = @@rowcount
			IF @error <> 0 
				RETURN @error

			IF @rowcount = 0 
			BEGIN
				EXEC	 	amGetErrorMessage_sp 20004, "tmp/amtmclup.sp", 131, amtmplcl, @error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20004 @message
				RETURN 		20004
			END

			IF @ts <> @timestamp
			BEGIN
				EXEC 	amGetErrorMessage_sp 20003, "tmp/amtmclup.sp", 138, amtmplcl, @error_message = @message OUT
				IF @message IS NOT NULL RAISERROR 	20003 @message
				RETURN 		20003
			END
		END
	END
	ELSE 
	BEGIN
		
		EXEC @error = amtmcl_vwDelete_sp
						@timestamp,
						@company_id,
						@template_code,
						@classification_id,
						@last_modified_date,
						@modified_by
		RETURN @error
	END
END

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amtmcl_vwUpdate_sp] TO [public]
GO
