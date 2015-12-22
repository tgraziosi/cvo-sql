CREATE TABLE [dbo].[amastcls]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[classification_id] [dbo].[smSurrogateKey] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[classification_code] [dbo].[smClassificationCode] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amastcls_del_trg] 
ON 				[dbo].[amastcls] 
FOR 			DELETE 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





 
DECLARE @co_asset_id 			smSurrogateKey,
		@company_id				smCompanyID,
		@classification_id 		smSurrogateKey,
		@classification_code	smClassificationCode,
		@error				 	smErrorCode,
		@length					smSmallCounter
		


SELECT 	@co_asset_id = MIN(co_asset_id)
FROM 	deleted 

WHILE @co_asset_id IS NOT NULL 
BEGIN 




	
	SELECT 	@company_id	 = company_id
	FROM	deleted
	WHERE co_asset_id = @co_asset_id


	
	SELECT 	@classification_id 	= MIN(classification_id)
	FROM 	deleted 
	WHERE	co_asset_id 		= @co_asset_id
	AND		company_id			= @company_id




	
	WHILE @classification_id IS NOT NULL
	BEGIN
		
		
		SELECT 	@length					= length
		FROM 	amclshdr
		WHERE	classification_id 		= @classification_id
		AND company_id 			= @company_id

		IF @length > 0 
		BEGIN
				UPDATE 	amastact
				SET		up_to_date				= 0,
						last_modified_date		= GETDATE()
				FROM	amastact aa,
						amclsact cl
				WHERE	aa.co_asset_id			= @co_asset_id
				AND		aa.account_type_id		= cl.account_type
				AND cl.override_account_flag = 1
				AND		cl.classification_id = @classification_id
				AND cl.company_id			= @company_id

				SELECT @error = @@error
				IF @error <> 0
				BEGIN
					ROLLBACK TRANSACTION
					RETURN
				END
	 END
			
		 
		SELECT 	@classification_id 	= MIN(classification_id)
		FROM 	deleted 
		WHERE 	classification_id 	> @classification_id
		AND		co_asset_id			= @co_asset_id 
		AND		company_id 			= @company_id

	END	

	 
	SELECT 	@co_asset_id 	= MIN(co_asset_id)
	FROM 	deleted 
	WHERE 	co_asset_id 	> @co_asset_id 

END 





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amastcls_ins_trg] 
ON 				[dbo].[amastcls] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 






 


 
IF ( SELECT COUNT(i.co_asset_id) 
		FROM 	inserted i, 
				amasset f 
		WHERE 	f.co_asset_id = i.co_asset_id) <> @rowcount 
BEGIN 



	EXEC 		amGetErrorMessage_sp 20557, ".\\amastcls.itr", 122, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20557 @message 
	SELECT 		@rollback = 1 
END 


 
IF ( SELECT COUNT(i.classification_code) 
		FROM 	inserted i, 
				amcls c 
		WHERE 	c.company_id 			= i.company_id
		AND		c.classification_id		= i.classification_id
		AND		c.classification_code 	= i.classification_code) <> @rowcount 
BEGIN 




	EXEC 		amGetErrorMessage_sp 20559, ".\\amastcls.itr", 140, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20559 @message 
	SELECT 		@rollback = 1 			 
END 


 
IF @rollback = 1 
BEGIN 



	ROLLBACK TRANSACTION 
	RETURN 
END 

 
DECLARE @co_asset_id 			smSurrogateKey,
		@company_id				smCompanyID,
		@classification_id 		smSurrogateKey,
		@classification_code	smClassificationCode,
		@error				 	smErrorCode,
		@last_modified_date		smApplyDate,
		@user_id				smUserID,
		@changed				smLogical,
		@length					smSmallCounter
		


SELECT 	@co_asset_id = MIN(co_asset_id)
FROM 	inserted 


WHILE @co_asset_id IS NOT NULL 
BEGIN 




	
	SELECT 	@company_id	 = company_id
	FROM	inserted
	WHERE co_asset_id = @co_asset_id

	
	SELECT 	@classification_id 	= MIN(classification_id)
	FROM 	inserted 
	WHERE	co_asset_id 		= @co_asset_id
	AND		company_id			= @company_id




	
	WHILE @classification_id IS NOT NULL
	BEGIN
		 
		SELECT 
				@classification_code 	= classification_code,
				@user_id 				= modified_by 
		FROM	inserted 
		WHERE	co_asset_id 			= @co_asset_id 
		AND		company_id				= @company_id
		AND 	classification_id 		= @classification_id 
		
		SELECT 	@length					= length
		FROM 	amclshdr
		WHERE	classification_id 		= @classification_id
		AND		company_id 				= @company_id

		IF @length > 0 
		BEGIN
				UPDATE 	amastact
				SET		up_to_date				= 0,
						last_modified_date		= GETDATE()
				FROM	amastact aa,
						amclsact cl
				WHERE	aa.co_asset_id			= @co_asset_id
				AND		aa.account_type_id		= cl.account_type
				AND cl.override_account_flag = 1
				AND		cl.classification_id = @classification_id
				AND cl.company_id			= @company_id

				SELECT @error = @@error
				IF @error <> 0
				BEGIN
					ROLLBACK TRANSACTION
					RETURN
				END

		END
		

		 
	 	SELECT @last_modified_date = GETDATE() 

		EXEC @error = amLogAssetClsChanges_sp 
						@co_asset_id,
						@last_modified_date,
						@user_id,
						@classification_id,
						NULL, 		
						@classification_code,
						@changed 		OUTPUT 
		
		IF @error <> 0 
		BEGIN 



			ROLLBACK TRANSACTION 
			RETURN 
		END 
	
		 
		SELECT 	@classification_id 	= MIN(classification_id)
		FROM 	inserted 
		WHERE 	classification_id 	> @classification_id
		AND		co_asset_id			= @co_asset_id 
		AND		company_id 			= @company_id

	END	

	 
	SELECT 	@co_asset_id = MIN(co_asset_id)
	FROM 	inserted 
	WHERE 	co_asset_id > @co_asset_id 

END 





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amastcls_upd_trg] 
ON 				[dbo].[amastcls] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 				smCounter, 
	@keycount 				smCounter, 
	@rollback 				smLogical, 
	@message 				smErrorLongDesc,
	@length					smSmallCounter
	
SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





 
SELECT 	@keycount 			= COUNT(i.classification_id) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.classification_id	= d.classification_id 
AND 	i.co_asset_id 		= d.co_asset_id 






IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20558, ".\\amastcls.utr", 125, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20558 @message 
	SELECT 		@rollback = 1 
END 

 
IF UPDATE(classification_code)
BEGIN
	IF ( SELECT COUNT(i.company_id) 
			FROM 	inserted i, 
					amcls c 
			WHERE 	c.company_id 			= i.company_id
			AND		c.classification_id		= i.classification_id
			AND		c.classification_code 	= i.classification_code) <> @rowcount 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20560, ".\\amastcls.utr", 147, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20560 @message 
		SELECT 		@rollback = 1 			 
	END 
END

 
IF @rollback = 1 
BEGIN 



	ROLLBACK TRANSACTION 
	RETURN 
END 

 
IF UPDATE(classification_code)
BEGIN
	DECLARE @co_asset_id 				smSurrogateKey,
			@company_id					smCompanyID,
			@classification_id 			smSurrogateKey,
			@old_classification_code	smClassificationCode,
			@new_classification_code	smClassificationCode,
			@error				 		smErrorCode,
			@last_modified_date			smApplyDate,
			@user_id					smUserID,
			@changed					smLogical
			 

	
	SELECT 	@co_asset_id = MIN(co_asset_id)
	FROM 	inserted 

	
	WHILE @co_asset_id IS NOT NULL 
	BEGIN 
	



		
		SELECT 	@company_id	 = company_id
		FROM	inserted
		WHERE co_asset_id = @co_asset_id

		
		SELECT 	@classification_id 	= MIN(classification_id)
		FROM 	inserted 
		WHERE	co_asset_id 		= @co_asset_id
		AND		company_id			= @company_id

	


		
		WHILE @classification_id IS NOT NULL
		BEGIN
			 
			SELECT 	@old_classification_code 	= classification_code
			FROM	deleted
			WHERE	co_asset_id 				= @co_asset_id 
			AND		company_id					= @company_id
			AND 	classification_id 			= @classification_id 
			
			 
			SELECT 	@new_classification_code 	= classification_code,
					@user_id 					= modified_by 
			FROM	inserted 
			WHERE	co_asset_id 				= @co_asset_id 
			AND		company_id					= @company_id
			AND 	classification_id 			= @classification_id 
			
			 
		 	SELECT @last_modified_date = GETDATE() 

			EXEC @error = amLogAssetClsChanges_sp 
							@co_asset_id,
							@last_modified_date,
							@user_id,
							@classification_id,
							@old_classification_code, 		
							@new_classification_code,
							@changed 		OUTPUT 
			
			IF @error <> 0 
			BEGIN 
	


				ROLLBACK TRANSACTION 
				RETURN 
			END 		
			
			IF @old_classification_code <> @new_classification_code
			BEGIN

			


			 
				
				SELECT 	@length					= length
				FROM 	amclshdr
				WHERE	classification_id 		= @classification_id
				AND 	company_id				= @company_id

				IF @length > 0 
				BEGIN

					UPDATE 	amastact
					SET		up_to_date				= 0,
							last_modified_date		= GETDATE()
					FROM	amastact aa,
							amclsact cl
					WHERE	aa.co_asset_id			= @co_asset_id
					AND		aa.account_type_id		= cl.account_type
					AND cl.override_account_flag = 1
					AND		cl.classification_id = @classification_id
					AND cl.company_id			= @company_id

					SELECT @error = @@error
					IF @error <> 0
					BEGIN
						ROLLBACK TRANSACTION
						RETURN
					END
													
				END
			END	
					
			 
			SELECT 	@classification_id 	= MIN(classification_id)
			FROM 	inserted 
			WHERE 	classification_id 	> @classification_id
			AND		co_asset_id			= @co_asset_id 
			AND		company_id 			= @company_id

		END	

		 
		SELECT 	@co_asset_id = MIN(co_asset_id)
		FROM 	inserted 
		WHERE 	co_asset_id > @co_asset_id 

	END 
END





GO
CREATE UNIQUE NONCLUSTERED INDEX [amastcls_ind_1] ON [dbo].[amastcls] ([co_asset_id], [company_id], [classification_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amastcls_ind_0] ON [dbo].[amastcls] ([company_id], [classification_id], [co_asset_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastcls].[classification_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastcls].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastcls].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amastcls] TO [public]
GO
GRANT SELECT ON  [dbo].[amastcls] TO [public]
GO
GRANT INSERT ON  [dbo].[amastcls] TO [public]
GO
GRANT DELETE ON  [dbo].[amastcls] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastcls] TO [public]
GO
