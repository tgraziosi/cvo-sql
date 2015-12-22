SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amChangeAssetCls_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@co_asset_id 	smSurrogateKey,
	@classification_code 	smClassificationCode,
	@user_id	 	smUserID
) 
AS

DECLARE 
	@rowcount 		smCounter,
	@error 			smErrorCode,
	@ts 			timestamp,
	@message 		smErrorLongDesc,
	@cur_cls_code	smClassificationCode,
	@changed		smLogical,
	@apply_date		smApplyDate

IF @classification_code IS NOT NULL
BEGIN
	IF NOT EXISTS(SELECT 	company_id 
					FROM	amastcls
					WHERE	company_id			= @company_id
					AND		classification_id	= @classification_id
					AND		co_asset_id			= @co_asset_id)
	BEGIN
		INSERT INTO amastcls
		(
			company_id,
			classification_id,
			co_asset_id,
			classification_code,
			last_modified_date,
			modified_by
		)
		VALUES
		(
			@company_id,
			@classification_id,
			@co_asset_id,
			@classification_code,
			GETDATE(),
			@user_id
		)

		RETURN @@error
		
	END
	ELSE 
	BEGIN
		UPDATE amastcls 
		SET
				classification_code 	=	@classification_code,
				last_modified_date 	=	GETDATE(),
				modified_by 	=	@user_id
		WHERE	co_asset_id 	=	@co_asset_id
		AND		company_id 	=	@company_id
		AND		classification_id 	=	@classification_id 
			
		RETURN @@error
	END
END
ELSE 
BEGIN
	SELECT 	@cur_cls_code 		= classification_code
	FROM 	amastcls 
	WHERE	co_asset_id 	= @co_asset_id 
	AND		company_id = @company_id 
	AND		classification_id = @classification_id 

	SELECT @rowcount = @@rowcount

	IF @rowcount > 0
	BEGIN
		DELETE 
		FROM 	amastcls 
		WHERE	co_asset_id 	= @co_asset_id 
		AND		company_id = @company_id 
		AND		classification_id = @classification_id 

		SELECT @error = @@error
		IF @error <> 0 
			RETURN @error

		ELSE 
		BEGIN

			SELECT	@apply_date	= GETDATE()
			
			EXEC @error = amLogAssetClsChanges_sp 
							@co_asset_id,
							@apply_date,	 
							@user_id,
							@classification_id,
							@cur_cls_code, 		
							NULL,
							@changed 		OUTPUT 
			
		END
	END
END

RETURN @error
GO
GRANT EXECUTE ON  [dbo].[amChangeAssetCls_sp] TO [public]
GO
