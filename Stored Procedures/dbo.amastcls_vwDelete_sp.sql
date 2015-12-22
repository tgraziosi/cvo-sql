SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastcls_vwDelete_sp]
(
	@timestamp 	timestamp,
	@co_asset_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@last_modified_date				varchar(30),
	@modified_by					smUserID
) as

DECLARE @rowcount 					int,
	 	@error 						int,
		@ts 						timestamp,
		@message 					varchar(255),
		@modified_date				smApplyDate,
		@cur_classification_code	smClassificationCode,
		@changed					smLogical,
		@apply_date					smApplyDate

SELECT	@modified_date	= CONVERT(datetime, @last_modified_date, 112)


SELECT	@cur_classification_code 	= classification_code 
FROM 	amastcls 
WHERE	co_asset_id 			= @co_asset_id 
AND		company_id 		= @company_id 
AND		classification_id 		= @classification_id 


BEGIN TRANSACTION
	DELETE 
	FROM 	amastcls 
	WHERE	co_asset_id 	= @co_asset_id 
	AND		company_id = @company_id 
	AND		classification_id = @classification_id 
	AND		timestamp = @timestamp

	SELECT @error = @@error, @rowcount = @@rowcount

	IF @error <> 0 
	BEGIN
		ROLLBACK TRANSACTION
		RETURN @error
	END

	ELSE 
	BEGIN
		IF @rowcount = 0 
		BEGIN
			
			SELECT 	@ts 				= timestamp 
			FROM 	amastcls 
			WHERE	co_asset_id 		= @co_asset_id 
			AND		company_id 			= @company_id 
			AND		classification_id 	= @classification_id

			SELECT @error = @@error, @rowcount = @@rowcount
			IF @error <> 0 
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @error
			END

			IF @rowcount = 0 
			BEGIN
				EXEC	 	amGetErrorMessage_sp 20002, "tmp/amascldl.sp", 129, amastcls, @error_message = @message out
				IF @message IS NOT NULL RAISERROR 	20002 @message
				ROLLBACK 	TRANSACTION
				RETURN 		20002
			END
			IF @ts <> @timestamp
			BEGIN
				EXEC	 	amGetErrorMessage_sp 20001, "tmp/amascldl.sp", 136, amastcls, @error_message = @message out
				IF @message IS NOT NULL RAISERROR 	20001 @message
				ROLLBACK 	TRANSACTION
				RETURN 		20001
			END
		END
		ELSE 
		BEGIN

			SELECT	@apply_date	= GETDATE()
			
			EXEC @error = amLogAssetClsChanges_sp 
							@co_asset_id,
							@apply_date,	 
							@modified_by,
							@classification_id,
							@cur_classification_code, 		
							NULL,
							@changed 		OUTPUT 
			
			IF @error <> 0 
			BEGIN 
		


				ROLLBACK TRANSACTION 
				RETURN @error
			END 
		END
	END

COMMIT TRANSACTION

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amastcls_vwDelete_sp] TO [public]
GO
