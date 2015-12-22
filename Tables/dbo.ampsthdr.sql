CREATE TABLE [dbo].[ampsthdr]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[posting_code] [dbo].[smPostingCode] NOT NULL,
[posting_code_description] [dbo].[smStdDescription] NOT NULL,
[last_updated] [dbo].[smApplyDate] NOT NULL,
[updated_by] [dbo].[smUserID] NOT NULL,
[date_created] [dbo].[smApplyDate] NOT NULL,
[created_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[ampsthdr_del_trg] 
ON 				[dbo].[ampsthdr] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@posting_code	smPostingCode,
	@category_code	smCategoryCode,
	@company_id		smCompanyID

SELECT @rollback 	= 0 

SELECT	@posting_code = MIN(posting_code)
FROM	deleted



WHILE @posting_code IS NOT NULL
BEGIN
	SELECT	@category_code = NULL
	
	SELECT	@category_code = MIN(category_code)
	FROM	amcat
	WHERE	posting_code	= @posting_code
	
	IF @category_code IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20536, ".\\ampsthdr.dtr", 78, @posting_code, @category_code, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20536 @message 
		SELECT 		@rollback = 1 
	END 
	ELSE
	BEGIN
			
		
		SELECT @company_id = company_id
		FROM deleted
		WHERE posting_code = @posting_code
		 
		DELETE ampstact
		WHERE posting_code = @posting_code
		AND company_id = @company_id
		 
	END

	
	SELECT	@posting_code 	= MIN(posting_code)
	FROM	deleted
	WHERE	posting_code	> @posting_code

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[ampsthdr_ins_trg] 
ON 				[dbo].[ampsthdr] 
FOR 			INSERT 
AS 

DECLARE 
	@rollback 			smLogical, 
	@rowcount 			smCounter, 
	@message 			smErrorLongDesc, 
	@error 				smErrorCode 
	 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 


INSERT ampstact(
				company_id,
				posting_code,
				account_type,
				account,
				last_updated,		 
 		updated_by, 
		 		date_created, 		 
 		created_by 

				)
SELECT 	i.company_id,
		i.posting_code,
		a.account_type,
		"",
		i.last_updated,
		i.updated_by,
		i.date_created,
		i.created_by
FROM amacctyp a,
	 inserted i

	
IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [ampsthdr_ind_0] ON [dbo].[ampsthdr] ([company_id], [posting_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ampsthdr_ind_1] ON [dbo].[ampsthdr] ([posting_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[ampsthdr].[posting_code_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampsthdr].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampsthdr].[created_by]'
GO
GRANT REFERENCES ON  [dbo].[ampsthdr] TO [public]
GO
GRANT SELECT ON  [dbo].[ampsthdr] TO [public]
GO
GRANT INSERT ON  [dbo].[ampsthdr] TO [public]
GO
GRANT DELETE ON  [dbo].[ampsthdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ampsthdr] TO [public]
GO
