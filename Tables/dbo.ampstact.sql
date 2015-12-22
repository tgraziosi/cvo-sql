CREATE TABLE [dbo].[ampstact]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[posting_code] [dbo].[smPostingCode] NOT NULL,
[account_type] [dbo].[smAccountTypeID] NOT NULL,
[account] [dbo].[smAccountCode] NOT NULL,
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


CREATE TRIGGER	[dbo].[ampstact_upd_trg] 
ON 				[dbo].[ampstact] 
FOR 			UPDATE 
AS 

DECLARE 
	@rollback 				smLogical, 
	@rowcount 				smCounter, 
	@message 				smErrorLongDesc, 
	@error 					smErrorCode, 
	@valid 					smLogical, 
	@posting_code 			smPostingCode, 
	@acct 					smAccountCode, 
	@old_acct 				smAccountCode,
	@account_type			smAccountTypeID,
	@company_id				smCompanyID 
	
SELECT @rowcount = @@rowcount 
SELECT @rollback = 0


 
SELECT 	@company_id = MIN(company_id)
FROM 	inserted 

WHILE @company_id IS NOT NULL
BEGIN

	 
	SELECT 	@posting_code = MIN(posting_code)
	FROM 	inserted 
	WHERE company_id 	= @company_id

	WHILE @posting_code IS NOT NULL 
	BEGIN
	 IF @posting_code <> "____SUSP"
	 BEGIN	

		SELECT 	@account_type = MIN(account_type)
		FROM 	inserted 
		WHERE company_id 	= @company_id
		AND		posting_code = @posting_code


		WHILE @account_type IS NOT NULL 
		BEGIN

			 
			SELECT 						
					@acct 			= account 						 
			FROM 	inserted 
			WHERE 	posting_code 	= @posting_code 
			AND company_id		= @company_id
			AND 	account_type 	= @account_type

			
			 
			SELECT 	
					@old_acct 		= account
			FROM 	deleted 
			WHERE 	posting_code 	= @posting_code
			AND		company_id 		= @company_id
			AND account_type 	= @account_type

			EXEC 	@error = amValidateAccountCode_sp @acct, @valid OUT 
			IF @error <> 0 
			OR @valid = 0 
			BEGIN 
				SELECT 	@rollback = 1 
			END 

			
			IF @acct <> @old_acct
			BEGIN
				UPDATE 	amastact
				SET		up_to_date			= 0,
						last_modified_date	= GETDATE()
				FROM	amastact aa,
						amasset a,
						amcat c
				WHERE	aa.co_asset_id 		= a.co_asset_id
				AND		aa.account_type_id	= @account_type
				AND		a.category_code		= c.category_code
				AND		c.posting_code		= @posting_code
				AND a.company_id		= @company_id

				SELECT @error = @@error
				IF @error <> 0
				BEGIN
					ROLLBACK TRANSACTION
					RETURN 
				END
			END
		
			
			 
			SELECT 	@account_type 	= MIN(account_type)
			FROM 	inserted 
			WHERE 	account_type > @account_type
			AND posting_code 	= @posting_code 
			AND company_id 		= @company_id
			
		 END 
	 END 

	  
	 SELECT 	@posting_code 	= MIN(posting_code)
	 FROM 	inserted 
	 WHERE 	posting_code 	> @posting_code 
	 AND company_id = @company_id
	
 END

 SELECT 	@company_id 	= MIN(company_id)
 FROM 	inserted 
	WHERE 	company_id 	> @company_id 
END 



IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [ampstact_ind_0] ON [dbo].[ampstact] ([company_id], [posting_code], [account_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampstact].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampstact].[created_by]'
GO
GRANT REFERENCES ON  [dbo].[ampstact] TO [public]
GO
GRANT SELECT ON  [dbo].[ampstact] TO [public]
GO
GRANT INSERT ON  [dbo].[ampstact] TO [public]
GO
GRANT DELETE ON  [dbo].[ampstact] TO [public]
GO
GRANT UPDATE ON  [dbo].[ampstact] TO [public]
GO
