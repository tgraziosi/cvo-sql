CREATE TABLE [dbo].[amcls]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[classification_id] [dbo].[smSurrogateKey] NOT NULL,
[classification_code] [dbo].[smClassificationCode] NOT NULL,
[classification_description] [dbo].[smStdDescription] NOT NULL,
[gl_override] [dbo].[smAccountOverride] NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amcls_del_trg] 
ON 				[dbo].[amcls] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 				smLogical, 
	@message 				smErrorLongDesc, 
	@classification_code	smClassificationCode,
	@classification_id		smSurrogateKey,
	@co_asset_id			smSurrogateKey,
	@company_id				smCompanyID,
	@asset_ctrl_num			smControlNumber,
	@template_code			smTemplateCode 

SELECT @rollback 	= 0 

SELECT	@company_id 		= MIN(company_id)
FROM	deleted


WHILE @company_id IS NOT NULL
BEGIN

	 
	SELECT	@classification_id 	= MIN(classification_id)
	FROM	deleted
	WHERE	company_id			= @company_id

	WHILE @classification_id IS NOT NULL
	BEGIN
		SELECT	@classification_code 	= MIN(classification_code)
		FROM	deleted
		WHERE	classification_id		= @classification_id
		AND		company_id				= @company_id

		WHILE @classification_code IS NOT NULL
		BEGIN
			SELECT	@co_asset_id 	= NULL,
					@template_code	= NULL
			
			SELECT	@co_asset_id		= MIN(co_asset_id)
			FROM	amastcls
			WHERE	classification_code = @classification_code
			AND		classification_id	= @classification_id
			AND		company_id			= @company_id
			
			IF @co_asset_id IS NOT NULL 
			BEGIN 
				SELECT	@asset_ctrl_num = asset_ctrl_num
				FROM	amasset
				WHERE	co_asset_id		= @co_asset_id
			
				EXEC 		amGetErrorMessage_sp 20543, ".\\amcls.dtr", 128, @classification_code, @asset_ctrl_num, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20543 @message 
				SELECT 		@rollback = 1 
			END 


			IF @rollback = 0
			BEGIN
				SELECT	@template_code		= MIN(template_code)
				FROM	amtmplcl
				WHERE	classification_code = @classification_code
				AND		classification_id	= @classification_id
				AND		company_id			= @company_id
				
				IF @template_code IS NOT NULL 
				BEGIN 
					EXEC 		amGetErrorMessage_sp 20567, ".\\amcls.dtr", 144, @classification_code, @template_code, @error_message = @message OUT 
					IF @message IS NOT NULL RAISERROR 	20567 @message 
					SELECT 		@rollback = 1 
				END 
			END

			
			SELECT	@classification_code 	= MIN(classification_code)
			FROM	deleted
			WHERE	classification_code		> @classification_code
			AND		classification_id		= @classification_id
			AND		company_id				= @company_id

		END

		
		SELECT	@classification_id 	= MIN(classification_id)
		FROM	deleted
		WHERE	classification_id	> @classification_id
		AND		company_id			= @company_id
	END

	
	SELECT	@company_id 	= MIN(company_id)
	FROM	deleted
	WHERE	company_id	> @company_id 	 

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amcls_ins_trg] 
ON 				[dbo].[amcls] 
FOR 			INSERT 
AS 

DECLARE @rowcount 			smCounter,
		@valid_count		smCounter, 
		@rollback 			smLogical, 
		@message 			smErrorLongDesc,
		@acct_level			smAcctLevel,
		@start_col			smSmallCounter,
		@length				smSmallCounter,
		@classification_id	smSurrogateKey,
		@company_id			smCompanyID,
		@invalid_override	smAccountOverride

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
IF ( SELECT 	COUNT(i.company_id) 
		FROM 	inserted i, 
				amclshdr cd 
		WHERE 	i.company_id 		= cd.company_id
		AND		i.classification_id = cd.classification_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20561, ".\\amcls.itr", 104, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20561 @message 
	SELECT 		@rollback = 1 
END 


IF @rollback = 1
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN
END




SELECT 	@company_id = MIN(company_id)
FROM	inserted

WHILE @company_id IS NOT NULL
BEGIN


	SELECT 	@classification_id = MIN(classification_id)
	FROM	inserted
	WHERE company_id = @company_id

	WHILE @classification_id IS NOT NULL
	BEGIN

		
		SELECT 	
				@start_col 			= start_col,
				@length				= length,
				@acct_level			= acct_level
		FROM 	amclshdr
		WHERE	classification_id 	= @classification_id
		AND company_id			= @company_id
		
	






		
		SELECT	@rowcount 			= COUNT(DISTINCT gl_override)
		FROM	inserted
		WHERE	classification_id 	= @classification_id
		AND		gl_override			IS NOT NULL
		

	



		SELECT	@invalid_override = ""

		
		IF @acct_level = 0
		BEGIN
			SELECT 	@valid_count 		= COUNT(DISTINCT i.gl_override)
			FROM	glchart 	glc,
					inserted 	i
			WHERE 	i.gl_override 		= SUBSTRING(glc.account_code, @start_col, @length) 
			AND		i.classification_id = @classification_id
			AND		i.company_id		= @company_id
			AND		i.gl_override		IS NOT NULL
			
			IF @rowcount = 1
				SELECT 	@invalid_override 	= ISNULL(i.gl_override, "")
				FROM	inserted 	i
				WHERE	i.classification_id = @classification_id
				AND		i.company_id		= @company_id
			ELSE
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glchart 	glc,
						inserted 	i
				WHERE 	i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
				AND		i.gl_override 		NOT IN (SELECT SUBSTRING(glc.account_code, @start_col, @length)
													FROM glchart)

		END
		ELSE IF @acct_level = 1
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg1 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL

			IF @rowcount <> @valid_count
			BEGIN
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg1 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
	


			END
		END
		ELSE IF @acct_level = 2
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg2 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL

			IF @rowcount <> @valid_count
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg2 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
		END
		ELSE IF @acct_level = 3
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg3 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL
			
			IF @rowcount <> @valid_count
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg3 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
		END
		ELSE IF @acct_level = 4
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg4 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL
			
			IF @rowcount <> @valid_count
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg4 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
		END

	




		IF @rowcount <> @valid_count
		BEGIN
			EXEC 		amGetErrorMessage_sp 20130, ".\\amcls.itr", 283, @invalid_override, @error_message = @message out
			IF @message IS NOT NULL RAISERROR	20130 @message
			SELECT 		@rollback = 1
		END

		
		SELECT 	@classification_id 	= MIN(classification_id)
		FROM	inserted
		WHERE 	classification_id 	> @classification_id
		AND 	company_id 			= @company_id
	END


	SELECT 	@company_id 	= MIN(company_id)
	FROM	inserted
	WHERE 	company_id 	> @company_id



END

IF @rollback = 1
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amcls_upd_trg] 
ON 				[dbo].[amcls] 
FOR 			UPDATE 
AS 

DECLARE @keycount				smCounter,
		@rowcount 				smCounter,
		@valid_count			smCounter, 
		@rollback 				smLogical,
		@error					smErrorCode, 
		@message 				smErrorLongDesc,
		@acct_level				smAcctLevel,
		@start_col				smSmallCounter,
		@length					smSmallCounter,
		@classification_id		smSurrogateKey,
		@company_id				smCompanyID,
		@invalid_override		smAccountOverride,
		@classification_code	smClassificationCode,
 @old_gl_override 	smAccountOverride,
 @new_gl_override 	smAccountOverride


SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount				= COUNT(i.classification_id) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.classification_id 	= d.classification_id 
AND 	i.classification_code 	= d.classification_code 

IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20542, ".\\amcls.utr", 142, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20542 @message 
	
	
	ROLLBACK TRANSACTION 
	RETURN
END 







SELECT 	@company_id = MIN(company_id)
FROM	inserted

WHILE @company_id IS NOT NULL
BEGIN


	SELECT 	@classification_id = MIN(classification_id)
	FROM	inserted
	WHERE company_id = @company_id
	
	WHILE @classification_id IS NOT NULL
	BEGIN

		
		SELECT 	
				@start_col 				= start_col,
				@length					= length,
				@acct_level				= acct_level
		FROM 	amclshdr
		WHERE	classification_id 		= @classification_id
											
	






		
		SELECT	@rowcount 			= COUNT(DISTINCT gl_override)
		FROM	inserted
		WHERE	classification_id 	= @classification_id
		AND		company_id 			= @company_id
		AND		gl_override			IS NOT NULL
		

	



		
		IF @acct_level = 0
		BEGIN
			SELECT 	@valid_count 		= COUNT(DISTINCT i.gl_override)
			FROM	glchart 	glc,
					inserted 	i
			WHERE 	i.gl_override 		= SUBSTRING(glc.account_code, @start_col, @length) 
			AND		i.classification_id = @classification_id
			AND		i.company_id		= @company_id
			AND		i.gl_override		IS NOT NULL
			
			IF @rowcount = 1
				SELECT 	@invalid_override 	= isnull(i.gl_override, "")
				FROM	inserted 	i
				WHERE	i.classification_id = @classification_id
				AND		i.company_id		= @company_id
			ELSE
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glchart 	glc,
						inserted 	i
				WHERE 	i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
				AND		i.gl_override 		NOT IN (SELECT 	SUBSTRING(glc.account_code, @start_col, @length)
													FROM 	glchart)

		END
		ELSE IF @acct_level = 1
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg1 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL

			IF @rowcount <> @valid_count
			BEGIN
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg1 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
	


			END
		END
		ELSE IF @acct_level = 2
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg2 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL

			IF @rowcount <> @valid_count
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg2 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
		END
		ELSE IF @acct_level = 3
		BEGIN
			SELECT 	@valid_count 			= COUNT(DISTINCT i.gl_override)
			FROM	glseg3 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL
			
			IF @rowcount <> @valid_count
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg3 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
		END
		ELSE IF @acct_level = 4
		BEGIN
			SELECT 	@valid_count			= COUNT(DISTINCT i.gl_override)
			FROM	glseg4 gls,
					inserted i
			WHERE 	gls.seg_code 			= i.gl_override
			AND		i.classification_id 	= @classification_id
			AND		i.company_id			= @company_id
			AND		i.gl_override			IS NOT NULL
			
			IF @rowcount <> @valid_count
				SELECT 	@invalid_override 	= MIN(i.gl_override)
				FROM	glseg4 		gls,
						inserted 	i
				WHERE	i.gl_override 		<> gls.seg_code
				AND		i.classification_id = @classification_id
				AND		i.company_id		= @company_id
				AND		i.gl_override		IS NOT NULL
		END

	



		IF @rowcount <> @valid_count
		BEGIN
			EXEC 		amGetErrorMessage_sp 20130, ".\\amcls.utr", 320, @invalid_override, @error_message = @message out
			IF @message IS NOT NULL RAISERROR	20130 @message
			SELECT 		@rollback = 1
		END

		IF @length > 0 
		BEGIN
			
			SELECT 	@classification_code 	= MIN(classification_code)
			FROM	inserted
			WHERE	company_id				= @company_id
			AND		classification_id		= @classification_id

			WHILE @classification_code IS NOT NULL
			BEGIN

				SELECT 	@old_gl_override		= gl_override
				FROM	deleted
				WHERE	company_id				= @company_id
				AND		classification_id		= @classification_id
				AND		classification_code		= @classification_code

				SELECT 	@new_gl_override		= gl_override
				FROM	inserted
				WHERE	company_id				= @company_id
				AND		classification_id		= @classification_id
				AND		classification_code		= @classification_code

				IF (@old_gl_override IS NULL AND @new_gl_override IS NOT NULL)
				OR (@old_gl_override IS NOT NULL AND @new_gl_override IS NULL)
				OR (@old_gl_override IS NOT NULL AND @new_gl_override IS NOT NULL AND @old_gl_override <> @new_gl_override)
				BEGIN
					
						UPDATE 	amastact
						SET		up_to_date				= 0,
								last_modified_date		= GETDATE()
						FROM	amastact aa,
								amastcls ac,
								amclsact cl
						WHERE	aa.co_asset_id			= ac.co_asset_id
						AND		ac.company_id			= @company_id
						AND		ac.classification_id	= @classification_id
						AND		ac.classification_code	= @classification_code
						AND		aa.account_type_id		= cl.account_type
						AND		cl.classification_id = ac.classification_id
						AND cl.company_id = ac.company_id
						AND		cl.override_account_flag = 1

						SELECT @error = @@error
						IF @error <> 0
						BEGIN
							ROLLBACK TRANSACTION
							RETURN
						END
										
				END
			
				SELECT 	@classification_code 	= MIN(classification_code)
				FROM	inserted
				WHERE	company_id				= @company_id
				AND		classification_id		= @classification_id
				AND		classification_code		> @classification_code
			END
		END	
		
		
		
		SELECT 	@classification_id 	= MIN(classification_id)
		FROM	inserted
		WHERE 	classification_id 	> @classification_id
		AND 	company_id 			= @company_id

		
	END

	SELECT 	@company_id 	= MIN(company_id)
	FROM	inserted
	WHERE 	company_id 	> @company_id



END


	


IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amcls_ind_0] ON [dbo].[amcls] ([company_id], [classification_id], [classification_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcls].[classification_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amcls].[classification_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcls].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amcls] TO [public]
GO
GRANT SELECT ON  [dbo].[amcls] TO [public]
GO
GRANT INSERT ON  [dbo].[amcls] TO [public]
GO
GRANT DELETE ON  [dbo].[amcls] TO [public]
GO
GRANT UPDATE ON  [dbo].[amcls] TO [public]
GO
