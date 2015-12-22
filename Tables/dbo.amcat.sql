CREATE TABLE [dbo].[amcat]
(
[timestamp] [timestamp] NOT NULL,
[category_code] [dbo].[smCategoryCode] NOT NULL,
[category_description] [dbo].[smStdDescription] NOT NULL,
[posting_code] [dbo].[smPostingCode] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amcat_del_trg] 
ON 				[dbo].[amcat] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@result			smErrorCode,
	@message 		smErrorLongDesc, 
	@category_code 	smErrorParam,
	@asset_ctrl_num	smControlNumber,
	@template_code	smTemplateCode 

SELECT @rollback 	= 0 

SELECT	@category_code = MIN(category_code)
FROM	deleted

WHILE @category_code IS NOT NULL
BEGIN
	SELECT	@asset_ctrl_num = NULL,
			@template_code	= NULL
	
	SELECT	@asset_ctrl_num = MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	category_code	= @category_code
	
	 
	IF @asset_ctrl_num IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20523, ".\\amcat.dtr", 112, @category_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20523 @message 
		SELECT 		@rollback = 1 
	END 

	IF @rollback = 0
	BEGIN
		SELECT	@template_code 	= MIN(template_code)
		FROM	amtmplas
		WHERE	category_code	= @category_code
		
		IF @template_code IS NOT NULL 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20562, ".\\amcat.dtr", 125, @category_code, @template_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20562 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@category_code 	= MIN(category_code)
	FROM	deleted
	WHERE	category_code	> @category_code

END

IF @rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END


DELETE amcatbk
FROM 	amcatbk cb,
		deleted d
WHERE	d.category_code = cb.category_code

SELECT @result = @@error
IF @result <> 0
	ROLLBACK TRANSACTION

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amcat_ins_trg] 
ON 				[dbo].[amcat] 
FOR 			INSERT 
AS 

DECLARE 
	@rollback 		smLogical, 
	@rowcount 		smCounter, 
	@message 		smErrorLongDesc,
	@category_code	smCategoryCode,
	@posting_code	smPostingCode 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

SELECT	@category_code = MIN(category_code)
FROM	inserted

WHILE @category_code IS NOT NULL
BEGIN
	SELECT	@posting_code 	= posting_code
	FROM	inserted
	WHERE	category_code	= @category_code
	
	 
	IF NOT EXISTS (SELECT 	posting_code
					FROM 	ampsthdr 
					WHERE 	posting_code = @posting_code) 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20520, ".\\amcat.itr", 98, @posting_code, @category_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20520 @message 
		SELECT 		@rollback = 1 
	END 

	
	SELECT	@category_code 	= MIN(category_code)
	FROM	inserted
	WHERE	category_code	> @category_code

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amcat_upd_trg] 
ON 				[dbo].[amcat] 
FOR 			UPDATE 
AS 

DECLARE 
	@rollback 				smLogical, 
	@rowcount 				smCounter, 
	@keycount 				smCounter, 
	@error					smErrorCode,
	@message 				smErrorLongDesc, 
	@category_code			smCategoryCode,
	@posting_code			smPostingCode, 
	@old_posting_code		smPostingCode 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount 		= COUNT(i.category_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.category_code = d.category_code 






IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20522, ".\\amcat.utr", 117, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20522 @message 
	SELECT 		@rollback = 1 
END 


IF UPDATE(posting_code)
BEGIN
	SELECT	@category_code = MIN(category_code)
	FROM	inserted

	WHILE @category_code IS NOT NULL
	BEGIN
		SELECT	@posting_code 	= posting_code
		FROM	inserted
		WHERE	category_code	= @category_code
		
		SELECT	@old_posting_code 	= posting_code
		FROM	deleted
		WHERE	category_code	= @category_code
		
		 
		IF NOT EXISTS (SELECT 	posting_code
						FROM 	ampsthdr 
						WHERE 	posting_code = @posting_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20521, ".\\amcat.utr", 143, @posting_code, @category_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20521 @message 
			SELECT 		@rollback = 1 
		END 

		IF @posting_code <> @old_posting_code
		BEGIN
			
			
			UPDATE 	amastact
			SET		up_to_date			= 0,
					last_modified_date	= GETDATE()
			FROM	amastact aa,
					amasset a
			WHERE	aa.co_asset_id 		= a.co_asset_id
			AND		a.category_code		= @category_code

			SELECT @error = @@error
			IF @error <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN 
			END
		END
		
		
		SELECT	@category_code 	= MIN(category_code)
		FROM	inserted
		WHERE	category_code	> @category_code
	
	END
END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amcat_ind_0] ON [dbo].[amcat] ([category_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amcat].[category_description]'
GO
GRANT REFERENCES ON  [dbo].[amcat] TO [public]
GO
GRANT SELECT ON  [dbo].[amcat] TO [public]
GO
GRANT INSERT ON  [dbo].[amcat] TO [public]
GO
GRANT DELETE ON  [dbo].[amcat] TO [public]
GO
GRANT UPDATE ON  [dbo].[amcat] TO [public]
GO
