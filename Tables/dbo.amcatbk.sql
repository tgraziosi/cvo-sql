CREATE TABLE [dbo].[amcatbk]
(
[timestamp] [timestamp] NOT NULL,
[category_code] [dbo].[smCategoryCode] NOT NULL,
[book_code] [dbo].[smBookCode] NOT NULL,
[effective_date] [dbo].[smApplyDate] NOT NULL,
[depr_rule_code] [dbo].[smDeprRuleCode] NOT NULL,
[limit_rule_code] [dbo].[smLimitRuleCode] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amcatbk_ins_trg] 
ON 				[dbo].[amcatbk] 
FOR 			INSERT 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc,
	@category_code	smCategoryCode,
	@book_code		smBookCode,
	@depr_rule_code	smDeprRuleCode 

SELECT @rollback = 0 

SELECT	@category_code = MIN(category_code)
FROM	inserted

WHILE	@category_code IS NOT NULL
BEGIN

	IF NOT EXISTS (SELECT	category_code
					FROM	amcat
					WHERE	category_code = @category_code)
	BEGIN
		EXEC 		amGetErrorMessage_sp 20547, ".\\amcatbk.itr", 94, @category_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20547 @message 
		SELECT 		@rollback = 1 
	END

	SELECT	@book_code 		= MIN(book_code)
	FROM	inserted
	WHERE	category_code 	= @category_code

	WHILE @book_code IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT	book_code
						FROM	ambook
						WHERE	book_code = @book_code)
		BEGIN
			EXEC 		amGetErrorMessage_sp 20548, ".\\amcatbk.itr", 109, @book_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20548 @message 
			SELECT 		@rollback = 1 
		END

		SELECT	@depr_rule_code = MIN(depr_rule_code)
		FROM	inserted
		WHERE	category_code 	= @category_code
		AND		book_code		= @book_code

		WHILE @depr_rule_code IS NOT NULL
		BEGIN
			IF NOT EXISTS(SELECT	depr_rule_code
							FROM	amdprrul
							WHERE	depr_rule_code = @depr_rule_code)
			BEGIN
				EXEC 		amGetErrorMessage_sp 20549, ".\\amcatbk.itr", 125, @depr_rule_code, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20549 @message 
				SELECT 		@rollback = 1 
			END

			SELECT	@depr_rule_code = MIN(depr_rule_code)
			FROM	inserted
			WHERE	category_code	= @category_code
			AND		book_code		= @book_code
			AND		depr_rule_code	> @depr_rule_code
	 
	 	END

		SELECT	@book_code 		= MIN(book_code)
		FROM	inserted
		WHERE	category_code	= @category_code
		AND		book_code		> @book_code
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


CREATE TRIGGER 	[dbo].[amcatbk_upd_trg] 
ON 				[dbo].[amcatbk] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@keycount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc,
	@depr_rule_code	smDeprRuleCode 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount 			= COUNT(i.category_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.category_code 	= d.category_code 
AND 	i.book_code 		= d.book_code 
AND 	i.effective_date 	= d.effective_date 






IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20544, ".\\amcatbk.utr", 110, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20544 @message 
	SELECT 		@rollback = 1 
END 

 
IF UPDATE(depr_rule_code)
BEGIN 
	SELECT	@depr_rule_code = MIN(depr_rule_code)
	FROM	inserted 

	WHILE 	@depr_rule_code IS NOT NULL
	BEGIN
		
		IF NOT EXISTS (SELECT 	depr_rule_code
				 		FROM 	amdprrul 
				 		WHERE 	depr_rule_code = @depr_rule_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20550, ".\\amcatbk.utr", 130, @depr_rule_code, @error_message = @message OUT 
	 		IF @message IS NOT NULL RAISERROR 	20550 @message 
	 		SELECT 		@rollback = 1 
		END 
		
		SELECT	@depr_rule_code = MIN(depr_rule_code)
		FROM	inserted i
		WHERE	depr_rule_code	> @depr_rule_code
	END
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amcatbk_ind_0] ON [dbo].[amcatbk] ([category_code], [book_code], [effective_date]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amcatbk].[limit_rule_code]'
GO
GRANT REFERENCES ON  [dbo].[amcatbk] TO [public]
GO
GRANT SELECT ON  [dbo].[amcatbk] TO [public]
GO
GRANT INSERT ON  [dbo].[amcatbk] TO [public]
GO
GRANT DELETE ON  [dbo].[amcatbk] TO [public]
GO
GRANT UPDATE ON  [dbo].[amcatbk] TO [public]
GO
