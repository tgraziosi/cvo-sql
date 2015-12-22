CREATE TABLE [dbo].[ambook]
(
[timestamp] [timestamp] NOT NULL,
[book_code] [dbo].[smBookCode] NOT NULL,
[book_description] [dbo].[smStdDescription] NOT NULL,
[capitalization_threshold] [dbo].[smMoneyZero] NOT NULL,
[currency_code] [dbo].[smCurrencyCode] NOT NULL,
[allow_revaluations] [dbo].[smLogicalFalse] NOT NULL,
[allow_writedowns] [dbo].[smLogicalFalse] NOT NULL,
[allow_adjustments] [dbo].[smLogicalFalse] NOT NULL,
[suspend_depr] [dbo].[smLogicalFalse] NOT NULL,
[post_to_gl] [dbo].[smLogicalFalse] NOT NULL,
[gl_book_code] [dbo].[smBookCode] NULL,
[depr_if_less_than_yr] [dbo].[smLogicalTrue] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[ambook_del_trg] 
ON 				[dbo].[ambook] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@book_code 		smBookCode, 
	@asset_ctrl_num	smControlNumber,
	@category_code	smCategoryCode 

SELECT @rollback 	= 0 

SELECT	@book_code = MIN(book_code)
FROM	deleted

WHILE @book_code IS NOT NULL
BEGIN
	SELECT	@asset_ctrl_num = NULL,
			@category_code	= NULL
	
	SELECT	@category_code 	= MIN(category_code)
	FROM	amcatbk
	WHERE	book_code		= @book_code
	
	IF @category_code IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20527, ".\\ambook.dtr", 95, @book_code, @category_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20527 @message 
		SELECT 		@rollback = 1 
	END 
	ELSE
	BEGIN

		SELECT	@asset_ctrl_num = MIN(a.asset_ctrl_num)
		FROM	amasset	a,
				amastbk	ab
		WHERE	book_code		= @book_code
		AND		ab.co_asset_id	= a.co_asset_id
		
		IF @asset_ctrl_num IS NOT NULL 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20528, ".\\ambook.dtr", 110, @book_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20528 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@book_code 	= MIN(book_code)
	FROM	deleted
	WHERE	book_code	> @book_code

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[ambook_ins_trg] 
ON 				[dbo].[ambook] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@company_id 	smCompanyID, 
	@currency_code 	smCurrencyCode, 
	@error 			smErrorCode 

SELECT @rowcount = @@rowcount 

 
EXEC @error = amGetCompanyID_sp 
				@company_id OUTPUT 
IF @error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END
	
EXEC 	@error = amGetCurrencyCode_sp 
					@company_id, 
					@currency_code OUTPUT 
IF @error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

 
UPDATE 	ambook 
SET 	currency_code 	= @currency_code 
FROM	inserted i,
		ambook b
WHERE 	i.book_code 	= b.book_code 

SELECT @error = @@error 
IF @error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END
	
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[ambook_upd_trg] 
ON 				[dbo].[ambook] 
FOR 			UPDATE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@rowcount 		smCounter, 
	@keycount 		smCounter, 
	@message 		smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount = COUNT(i.book_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.book_code = d.book_code 

IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20526, ".\\ambook.utr", 92, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20526 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

GO
CREATE UNIQUE CLUSTERED INDEX [ambook_ind_0] ON [dbo].[ambook] ([book_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[ambook].[book_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ambook].[capitalization_threshold]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[ambook].[currency_code]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ambook].[allow_revaluations]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[ambook].[allow_revaluations]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ambook].[allow_writedowns]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[ambook].[allow_writedowns]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ambook].[allow_adjustments]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[ambook].[allow_adjustments]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ambook].[suspend_depr]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[ambook].[suspend_depr]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ambook].[post_to_gl]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[ambook].[post_to_gl]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ambook].[depr_if_less_than_yr]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[ambook].[depr_if_less_than_yr]'
GO
GRANT REFERENCES ON  [dbo].[ambook] TO [public]
GO
GRANT SELECT ON  [dbo].[ambook] TO [public]
GO
GRANT INSERT ON  [dbo].[ambook] TO [public]
GO
GRANT DELETE ON  [dbo].[ambook] TO [public]
GO
GRANT UPDATE ON  [dbo].[ambook] TO [public]
GO
