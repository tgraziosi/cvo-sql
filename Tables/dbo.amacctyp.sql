CREATE TABLE [dbo].[amacctyp]
(
[timestamp] [timestamp] NOT NULL,
[account_type] [dbo].[smAccountTypeID] NOT NULL,
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[income_account] [dbo].[smLogicalTrue] NOT NULL,
[negate_value] [dbo].[smLogicalFalse] NOT NULL,
[display_order] [dbo].[smCounter] NOT NULL,
[account_type_name] [dbo].[smName] NOT NULL,
[account_type_short_name] [dbo].[smName] NOT NULL,
[account_type_description] [dbo].[smStdDescription] NOT NULL,
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


CREATE TRIGGER 	[dbo].[amacctyp_del_trg] 
ON 				[dbo].[amacctyp] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@param			smErrorParam,
	@account_type	smAccountTypeID,
	@account_type_name smName,
	@trx_ctrl_num	smControlNumber


SELECT @rollback 	= 0 

IF EXISTS (SELECT 	process_id
			FROM 	amco
			WHERE 	process_id != 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20122, ".\\amaccttp.dtr", 72, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20122 @message 
	SELECT @rollback = 1	
END
ELSE
BEGIN
	SELECT	@trx_ctrl_num 	= MIN(trx_ctrl_num)
	FROM	amtrxhdr
	WHERE	posting_flag 	= 100
	AND		trx_type		= 50
		
	IF @trx_ctrl_num IS NOT NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 20191, ".\\amaccttp.dtr", 86, @trx_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20191 @message
		SELECT @rollback = 1	
	END

END

IF @rollback = 0
BEGIN



	SELECT	@account_type = MIN(account_type)
	FROM	deleted

	WHILE @account_type IS NOT NULL
	BEGIN

		IF EXISTS( SELECT 	account_type_id 
			 FROM 	amvalues
				WHERE 	account_type_id = @account_type
			 )

		BEGIN
			SELECT		@account_type_name = account_type_name
			FROM		amacctyp
			WHERE		account_type = @account_type

			EXEC 		amGetErrorMessage_sp 20590, ".\\amaccttp.dtr", 114, @account_type_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20590 @message 
			SELECT 		@rollback = 1 


		END
	
		DELETE ampstact
		WHERE account_type = @account_type	
	
		IF @@error <> 0 
		 SELECT @rollback 	= 1

	
		DELETE amclsact
		WHERE account_type = @account_type	 	
		IF @@error <> 0 
		 SELECT @rollback 	= 1

	
		DELETE amastact
		WHERE account_type_id = @account_type	 	
		IF @@error <> 0 
		 SELECT @rollback 	= 1

	
			 
		
		SELECT	@account_type 	= MIN(account_type)
		FROM	deleted
		WHERE	account_type		> @account_type

	END 

END	

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacctyp_ins_trg] 
ON 				[dbo].[amacctyp] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@account_type	smAccountTypeID, 
	@error 			smErrorCode,
	@todays			smApplyDate,
	@trx_ctrl_num	smControlNumber
 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 






IF EXISTS (SELECT 	process_id
			FROM 	amco
			WHERE 	process_id != 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20122, ".\\amaccttp.itr", 77, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20122 @message 
	SELECT @rollback = 1	
END

ELSE
BEGIN
	SELECT	@trx_ctrl_num 	= MIN(trx_ctrl_num)
	FROM	amtrxhdr
	WHERE	posting_flag 	= 100
	AND		trx_type		= 50
		
	IF @trx_ctrl_num IS NOT NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 20191, ".\\amaccttp.itr", 92, @trx_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20191 @message
		SELECT @rollback = 1	
	END

END

IF @rollback = 0 
BEGIN


	SELECT @todays = GETDATE()
	SELECT	@account_type = MIN(account_type)
	FROM	inserted

	WHILE 	@account_type IS NOT NULL
	BEGIN
	
		INSERT ampstact(
				company_id,
				posting_code,
				account_type,
				account,
				date_created,
				created_by,
				last_updated,
				updated_by	
				)
		SELECT 	a.company_id,
				a.posting_code,
				@account_type,
				"",
				@todays,
				i.updated_by,
				@todays,
				i.updated_by	
		FROM ampsthdr a,
			 inserted i


		IF @@error <> 0 
			 SELECT @rollback 	= 1


	 
	
		INSERT amclsact(
				company_id,
				classification_id,
				account_type,
				override_account_flag,
				date_created,
				created_by,
				last_updated,
				updated_by	
				
				)
		SELECT 	a.company_id,
			a.classification_id,
			@account_type,
			0,
			@todays,
			i.updated_by,
			@todays,
			i.updated_by
		FROM 	amclshdr a, 
			inserted i
		WHERE i.account_type = @account_type			 
			

		IF @@error <> 0
			SELECT @rollback 	= 1


		INSERT amastact(
			co_asset_id,
	 	account_type_id,
	 	account_code,
			up_to_date,
			last_modified_date
				 )
		SELECT	a.co_asset_id,
			@account_type,
			"",
			0,
			@todays
		FROM 	amasset a
		WHERE a.activity_state <> 101
				
	
			 
		
		SELECT	@account_type 	= MIN(account_type)
		FROM	inserted
		WHERE	account_type		> @account_type

	END	 
END 


IF @rollback = 1 
	ROLLBACK TRANSACTION 




GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amacctyp_upd_trg] 
ON 				[dbo].[amacctyp] 
FOR 			UPDATE 
AS
DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@param			smErrorParam,
	@old_account_type	smAccountTypeID,
	@new_account_type	smAccountTypeID,
	@account_type_name smName,
	@trx_ctrl_num	smControlNumber


SELECT @rollback 	= 0 

IF EXISTS (SELECT 	process_id
			FROM 	amco
			WHERE 	process_id != 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 
							20122, ".\\amaccttp.utr", 72, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20122 @message 
	SELECT @rollback = 1	
END
ELSE
BEGIN
	SELECT	@trx_ctrl_num 	= MIN(trx_ctrl_num)
	FROM	amtrxhdr
	WHERE	posting_flag 	= 100
	AND		trx_type		= 50
		
	IF @trx_ctrl_num IS NOT NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 20191, ".\\amaccttp.utr", 86, @trx_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20191 @message
		SELECT @rollback = 1	
	END

END

IF @rollback = 0
BEGIN



	SELECT	@account_type_name = MIN(account_type_name)
	FROM	deleted

	WHILE @account_type_name IS NOT NULL
	BEGIN


		SELECT	@old_account_type = account_type
		FROM	deleted
		WHERE	account_type_name = @account_type_name

		
		IF EXISTS( SELECT 	account_type_id 
			 FROM 	amvalues
				WHERE 	account_type_id = @old_account_type
			 )

		BEGIN
			
			EXEC 		amGetErrorMessage_sp 20590, ".\\amaccttp.utr", 119, @account_type_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20590 @message 
			SELECT 		@rollback = 1 


		END


		SELECT @new_account_type	= account_type
		FROM 	inserted
		WHERE	account_type_name 	= @account_type_name
	
		IF (@rollback = 0 AND @new_account_type <> @old_account_type)
		BEGIN

			
			UPDATE 	ampstact
			SET		account_type	= @new_account_type
			WHERE 	account_type 	= @old_account_type	
	
			IF @@error <> 0 
		 		SELECT @rollback 	= 1

			
			UPDATE amclsact
			SET		account_type	= @new_account_type
			WHERE 	account_type 	= @old_account_type	
	
			IF @@error <> 0 
		 		SELECT @rollback 	= 1

			
			UPDATE 	amastact
			SET		account_type_id	= @new_account_type
			WHERE 	account_type_id	= @old_account_type	

			IF @@error <> 0 
		 		SELECT @rollback 	= 1

			
			UPDATE 	amtrxact
			SET		account_type	= @new_account_type
			WHERE 	account_type	= @old_account_type	

			IF @@error <> 0 
		 		SELECT @rollback 	= 1


	
		END
			 
		
		SELECT	@account_type_name 	= MIN(account_type_name)
		FROM	deleted
		WHERE	account_type_name		> @account_type_name

	END 

END	

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE NONCLUSTERED INDEX [amacctyp_ind_1] ON [dbo].[amacctyp] ([account_type]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amacctyp_ind_0] ON [dbo].[amacctyp] ([account_type_name]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amacctyp].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amacctyp].[system_defined]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amacctyp].[income_account]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amacctyp].[income_account]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amacctyp].[negate_value]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amacctyp].[negate_value]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacctyp].[display_order]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amacctyp].[account_type_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacctyp].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amacctyp].[created_by]'
GO
GRANT REFERENCES ON  [dbo].[amacctyp] TO [public]
GO
GRANT SELECT ON  [dbo].[amacctyp] TO [public]
GO
GRANT INSERT ON  [dbo].[amacctyp] TO [public]
GO
GRANT DELETE ON  [dbo].[amacctyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[amacctyp] TO [public]
GO
