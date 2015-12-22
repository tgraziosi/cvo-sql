CREATE TABLE [dbo].[amacct]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[account_code] [dbo].[smAccountCode] NOT NULL,
[account_reference_code] [dbo].[smAccountReferenceCode] NOT NULL,
[account_id] [dbo].[smSurrogateKey] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacct_del_trg] 
ON 				[dbo].[amacct] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@param			smErrorParam,
	@account_id		smSurrogateKey 

SELECT @rollback 	= 0 

SELECT	@account_id = MIN(account_id)
FROM	deleted

WHILE @account_id IS NOT NULL
BEGIN
	IF EXISTS (SELECT	account_id 
				FROM	amvalues
				WHERE	account_id = @account_id)
	BEGIN 
		SELECT		@param = RTRIM(CONVERT(char(255), @account_id))
		EXEC 		amGetErrorMessage_sp 20541, ".\\amacct.dtr", 89, @param, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20525 @message 
		SELECT 		@rollback = 1 
	END 

	
	SELECT	@account_id 	= MIN(account_id)
	FROM	deleted
	WHERE	account_id		> @account_id

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacct_ins_trg] 
ON 				[dbo].[amacct] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@company_id 	smCompanyID, 
	@account_code 	smAccountCode, 
	@acct_ref_code 	smAccountReferenceCode, 
	@account_id 	smSurrogateKey, 
	@error 			smErrorCode 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





 
IF ( SELECT COUNT(i.company_id) 
		FROM 	inserted 	i, 
				amco 		co 
		WHERE 	co.company_id = i.company_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20508, ".\\amacct.itr", 105, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20508 @message 
	SELECT 		@rollback = 1 
END 

 
IF (@rollback = 0) and (@rowcount = 1)
BEGIN 
	SELECT 	@company_id 	= company_id,
			@account_code 	= account_code,
			@acct_ref_code 	= account_reference_code,
			@account_id 	= account_id 
	FROM 	inserted 
	 
	IF @account_id = 0 
	BEGIN 
		EXEC @error = amNextKey_sp 
						8, 
						@account_id OUT 
		IF @error <> 0 
		BEGIN 



			ROLLBACK TRANSACTION 
			RETURN 
		END 
		
		UPDATE 	amacct 
		SET 	account_id 				= @account_id 
		WHERE 	company_id 				= @company_id 
		AND 	account_code 			= @account_code 
		AND 	account_reference_code 	= @acct_ref_code 

		SELECT @error = @@error
		IF @error <> 0 
		BEGIN 



			ROLLBACK TRANSACTION 
			RETURN 
		END 
			
	END 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 




GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacct_upd_trg] 
ON 				[dbo].[amacct] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 	smCounter, 
	@key_count 	smCounter, 
	@rollback 	smLogical, 
	@message 	smErrorLongDesc

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@key_count 					= COUNT(i.account_id) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.account_code 				= d.account_code 
AND 	i.account_reference_code 	= d.account_reference_code 

IF @key_count <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20540, ".\\amacct.utr", 97, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20540 @message
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE NONCLUSTERED INDEX [amacct_ind_1] ON [dbo].[amacct] ([account_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amacct_ind_0] ON [dbo].[amacct] ([company_id], [account_code], [account_reference_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amacct].[account_reference_code]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacct].[account_id]'
GO
GRANT REFERENCES ON  [dbo].[amacct] TO [public]
GO
GRANT SELECT ON  [dbo].[amacct] TO [public]
GO
GRANT INSERT ON  [dbo].[amacct] TO [public]
GO
GRANT DELETE ON  [dbo].[amacct] TO [public]
GO
GRANT UPDATE ON  [dbo].[amacct] TO [public]
GO
