CREATE TABLE [dbo].[amauto]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[automatic_id] [dbo].[smSurrogateKey] NOT NULL,
[trx_type] [dbo].[smTrxType] NOT NULL,
[auto_description] [dbo].[smStdDescription] NOT NULL,
[num_mask] [dbo].[smControlNumber] NOT NULL,
[automatic_next] [dbo].[smCounter] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amauto_upd_trg] 
ON 			[dbo].[amauto] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@company_id 	smCompanyID, 
	@automatic_id 	smSurrogateKey, 
	@num_mask 		smControlNumber, 
	@is_valid 		smLogical, 
	@error 			smLogical 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@company_id = MIN(company_id)
FROM 	inserted 

WHILE @company_id IS NOT NULL 
BEGIN 
	SELECT 	@automatic_id = MIN(automatic_id)
	FROM 	inserted 
	WHERE 	company_id = @company_id 

	WHILE 	@automatic_id IS NOT NULL 
	BEGIN 

		SELECT 	@num_mask 		= num_mask 
		FROM 	inserted 
		WHERE 	company_id 		= @company_id 
		AND 	automatic_id 	= @automatic_id 

		 
		EXEC @error = amValidControlMask_sp @num_mask, @is_valid OUT 

		IF 	(@error <> 0) OR (@is_valid = 0)
			SELECT 	@rollback = 1 

		 
		SELECT 	@automatic_id 	= MIN(automatic_id)
		FROM 	inserted 
		WHERE 	company_id 		= @company_id 
		AND 	automatic_id 	> @automatic_id 

	END 
	
	 
	SELECT 	@company_id = MIN(company_id)
	FROM 	inserted 
	WHERE 	company_id 	> @company_id 
			
END 

IF 	@rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amauto_ind_0] ON [dbo].[amauto] ([company_id], [automatic_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amauto].[automatic_id]'
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amauto].[trx_type]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amauto].[auto_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amauto].[automatic_next]'
GO
GRANT REFERENCES ON  [dbo].[amauto] TO [public]
GO
GRANT SELECT ON  [dbo].[amauto] TO [public]
GO
GRANT INSERT ON  [dbo].[amauto] TO [public]
GO
GRANT DELETE ON  [dbo].[amauto] TO [public]
GO
GRANT UPDATE ON  [dbo].[amauto] TO [public]
GO
