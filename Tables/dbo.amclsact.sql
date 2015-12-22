CREATE TABLE [dbo].[amclsact]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[classification_id] [dbo].[smSurrogateKey] NOT NULL,
[account_type] [dbo].[smAccountTypeID] NOT NULL,
[override_account_flag] [dbo].[smLogicalFalse] NOT NULL,
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


CREATE TRIGGER 	[dbo].[amclsact_upd_trg] 
ON 			[dbo].[amclsact] 
FOR 			UPDATE 
AS 

DECLARE @rowcount 				smCounter, 
		@rollback 				smLogical, 
		@message 				smErrorLongDesc, 
		@error 					smLogical, 
		@company_id				smCompanyID,
		@classification_id		smSurrogateKey,
		@account_type			smAccountTypeID,
		@old_override		smLogical,
		@new_override		smLogical
				
SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





SELECT 	@company_id = MIN(company_id)
FROM	inserted
WHILE 	@company_id IS NOT NULL 
BEGIN 

	SELECT 	@classification_id = MIN(classification_id)
	FROM 	inserted 
	WHERE 	company_id				= @company_id

	WHILE 	@classification_id IS NOT NULL 
	BEGIN 


		SELECT 	@account_type = MIN(account_type)
		FROM 	inserted 
		WHERE 	company_id				= @company_id
		AND		classification_id 		= @classification_id 

		WHILE 	@account_type IS NOT NULL 
		BEGIN
			SELECT 	@old_override		= override_account_flag	
			FROM 	deleted 
			WHERE 	company_id				= @company_id
			AND		classification_id 		= @classification_id 
			AND account_type			= @account_type

			SELECT 	@new_override		= override_account_flag
			FROM 	inserted 
			WHERE 	company_id				= @company_id
			AND		classification_id 		= @classification_id 
			AND account_type			= @account_type

			
			IF @old_override <> @new_override
			BEGIN
				UPDATE 	amastact
				SET		up_to_date			= 0,
						last_modified_date 	= GETDATE()
				WHERE 	account_type_id		= @account_type

				
				SELECT @error = @@error
				IF	@error <> 0
				BEGIN
					ROLLBACK TRANSACTION 
					RETURN
				END
			END

			 
			SELECT 	@account_type = MIN(account_type)
			FROM 	inserted 
			WHERE 	account_type 			> @account_type 
			AND 	company_id				= @company_id
			AND		classification_id 		= @classification_id 


			

		 END
		
		 
		SELECT 	@classification_id = MIN(classification_id)
		FROM 	inserted 
		WHERE 	classification_id > @classification_id 
		AND 	company_id				= @company_id

	END	

	 
	SELECT 	@company_id = MIN(company_id)
	FROM 	inserted 
	WHERE 	company_id > @company_id 
	
END


GO
CREATE UNIQUE CLUSTERED INDEX [amclsact_ind_0] ON [dbo].[amclsact] ([company_id], [classification_id], [account_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclsact].[classification_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amclsact].[override_account_flag]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amclsact].[override_account_flag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclsact].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclsact].[created_by]'
GO
GRANT REFERENCES ON  [dbo].[amclsact] TO [public]
GO
GRANT SELECT ON  [dbo].[amclsact] TO [public]
GO
GRANT INSERT ON  [dbo].[amclsact] TO [public]
GO
GRANT DELETE ON  [dbo].[amclsact] TO [public]
GO
GRANT UPDATE ON  [dbo].[amclsact] TO [public]
GO
