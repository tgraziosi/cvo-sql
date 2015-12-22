CREATE TABLE [dbo].[amclshdr]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[classification_id] [dbo].[smSurrogateKey] NOT NULL,
[classification_name] [dbo].[smClassificationName] NOT NULL,
[acct_level] [dbo].[smAcctLevel] NOT NULL,
[start_col] [dbo].[smSmallCounter] NOT NULL,
[length] [dbo].[smSmallCounter] NOT NULL,
[override_default] [dbo].[smAccountOverride] NULL,
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


CREATE TRIGGER 	[dbo].[amclshdr_del_trg] 
ON 			[dbo].[amclshdr]
FOR 			DELETE 
AS 

DECLARE @classification_name	smStdDescription,
		@message				smErrorLongDesc,
		@rowcount				smCounter,
		@rollback				smLogical





SELECT @rowcount = @@rowcount
SELECT @rollback = 0 

 
IF EXISTS ( 
		SELECT 	c.classification_code 
		FROM 	deleted d, 
				amcls c 
		WHERE 	c.company_id 		= d.company_id
		AND 	c.classification_id = d.classification_id
	 	)
BEGIN 
	 
	SELECT 		@classification_name = "these classifications" 

	EXEC 		amGetErrorMessage_sp 20012, ".\\amclshdr.dtr", 91, @classification_name, amclshdr, amcls, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20012 @message 
	SELECT 		@rollback = 1 

END
ELSE
BEGIN
	
				 
	DELETE amclsact
	FROM 	deleted d, 
			amclsact c 
	WHERE 	c.company_id 		= d.company_id
	AND 	c.classification_id = d.classification_id

 IF @@error <> 0
		SELECT @rollback = 1
END 

IF 	@rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amclshdr_ins_trg] 
ON 			[dbo].[amclshdr] 
FOR 			INSERT 
AS 

DECLARE @rowcount 				smCounter, 
		@rollback 				smLogical, 
		@message 				smErrorLongDesc, 
		@error 					smLogical, 
		@company_id				smCompanyID,
		@classification_id		smSurrogateKey,
		@classification_name	smStdDescription,
		@temp_str				char(35),		
		@override_default		smAccountCode,
		@acct_level				smAcctLevel,
		@start_col				smSmallCounter,
		@end_col				smSmallCounter,
		@length					smSmallCounter,
		@gl_mask_length			smSmallCounter,
		@gl_format				char(38), 		
		@separator_pos			smSmallCounter,
		@num_separators			smSmallCounter,
		@valid					smLogical,
		@natural_acct			smAcctLevel,
		@start_natural			smSmallCounter,
		@end_natural			smSmallCounter,
		@natural_format			char(35) 





SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 


SELECT 	@company_id = MIN(company_id)
FROM	inserted


WHILE @company_id IS NOT NULL
BEGIN


	
	SELECT 	@gl_format = account_format_mask 
	FROM	glco
	WHERE	company_id = @company_id

	SELECT 	@gl_format = RTRIM(@gl_format) + "***"

	SELECT 	@gl_mask_length	= CHARINDEX("***", @gl_format),
			@num_separators = 0

	IF @gl_mask_length = 0
		SELECT @gl_mask_length = 32
	ELSE
		SELECT @gl_mask_length = @gl_mask_length - 1

	SELECT @separator_pos = CHARINDEX( "-", @gl_format)
	WHILE @separator_pos > 0
	BEGIN
		SELECT @num_separators 	= @num_separators + 1
		SELECT @gl_format 		= SUBSTRING(@gl_format, 1, @separator_pos - 1) + SUBSTRING(@gl_format, @separator_pos + 1, 32 - @separator_pos)
		SELECT @separator_pos 	= CHARINDEX( "-", @gl_format)
	END

	SELECT @gl_mask_length = @gl_mask_length - @num_separators

	
	SELECT 	@natural_acct		= acct_level,
			@start_natural		= start_col,
			@natural_format		= LTRIM(RTRIM(acct_format)) + "***"
	FROM	glaccdef
	WHERE	natural_acct_flag	= 1

	
	SELECT	@end_natural 		= @start_natural + (CHARINDEX("***", @natural_format) - 1) - 1

	
	SELECT 	@classification_id 	= MIN(classification_id)
	FROM 	inserted 
	WHERE	company_id			= @company_id

	WHILE @classification_id IS NOT NULL 
	BEGIN 
		SELECT 	@classification_name 	= classification_name,
				@acct_level				= acct_level,
				@start_col				= start_col,
				@end_col				= start_col + length - 1,
				@length					= length,
				@override_default		= override_default
		FROM 	inserted 
		WHERE 	company_id				= @company_id
		AND		classification_id 		= @classification_id 
		
		
		IF (@end_col > @gl_mask_length)
		BEGIN
			EXEC 		amGetErrorMessage_sp 20131, ".\\amclshdr.itr", 193, @classification_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20131 @message 
			SELECT 		@rollback = 1 
		END
		
		
		SELECT @temp_str = RTRIM(@override_default) + "***"
		IF CHARINDEX("***", @temp_str) > 1
		BEGIN
			EXEC @error = amValidClsOverride_sp 
					@company_id, 
					@acct_level, 
					@start_col, 
					@length,
					@override_default,
					@valid OUTPUT
			IF (@valid = 0)
			BEGIN
				EXEC 		amGetErrorMessage_sp 20132, ".\\amclshdr.itr", 213, @override_default, @classification_name, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20132 @message 
				SELECT 		@rollback = 1 
			END
		END
		
	







		
		IF @acct_level = @natural_acct
		BEGIN
			EXEC 	amGetErrorMessage_sp 20133, ".\\amclshdr.itr", 232, @classification_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20133 @message 
			SELECT 		@rollback = 1 
		END
		ELSE
		BEGIN
			IF 	(@acct_level = 0)
			AND	(	(@start_col >= @start_natural AND @start_col <= @end_natural)
				OR	(@end_col >= @start_natural AND @end_col <= @end_natural))
			BEGIN
				EXEC 	amGetErrorMessage_sp 20133, ".\\amclshdr.itr", 242, @classification_name, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20133 @message 
				SELECT 		@rollback = 1 
			END
		END

		IF @rollback = 0
		BEGIN
			
			INSERT amclsact(
						company_id,
						classification_id,
						account_type,
						last_updated,		 
		 		updated_by, 
				 		date_created, 		 
		 		created_by 

						)
			SELECT 	i.company_id,
					i.classification_id,
					a.account_type,			
					i.last_updated,
					i.updated_by,
					i.date_created,
					i.created_by
			FROM amacctyp a,
				 inserted i 
			WHERE i.company_id = @company_id
			AND	 i.classification_id = @classification_id

			IF @@error <> 0	
				SELECT 		@rollback = 1 
		END

		 
		SELECT 	@classification_id 	= MIN(classification_id)
		FROM 	inserted 
		WHERE 	company_id			= @company_id
		AND		classification_id 	> @classification_id 
	END
	
	SELECT 	@company_id 	= MIN(company_id)
	FROM 	inserted 
	WHERE 	company_id 	> @company_id 
			
END 

		

IF 	@rollback = 1 
BEGIN



	ROLLBACK TRANSACTION 
	RETURN
END





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amclshdr_upd_trg] 
ON 			[dbo].[amclshdr] 
FOR 			UPDATE 
AS 

DECLARE @rowcount 				smCounter, 
		@rollback 				smLogical, 
		@message 				smErrorLongDesc, 
		@error 					smLogical, 
		@company_id				smCompanyID,
		@classification_id		smSurrogateKey,
		@classification_name	smStdDescription,
		@override_default		smAccountCode,
		@temp_str				char(35),		
		@override_length		smSmallCounter,
		@acct_level				smAcctLevel,
		@start_col				smSmallCounter,
		@length					smSmallCounter,
		@new_start_col			smSmallCounter,
		@new_end_col			smSmallCounter,
		@new_length				smSmallCounter,
		@gl_mask_length			smSmallCounter,
		@gl_format				char(38), 		
		@separator_pos			smSmallCounter,
		@num_separators			smSmallCounter,
		@valid					smLogical,
		@natural_acct			smAcctLevel,
		@start_natural			smSmallCounter,
		@end_natural			smSmallCounter,
		@natural_format			char(35) 		
				
SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 


IF UPDATE(acct_level) OR UPDATE(start_col) OR UPDATE(length) OR UPDATE(override_default)
BEGIN
	
	SELECT 	@company_id = MIN(company_id)
	FROM	inserted

	
	SELECT 	@gl_format = account_format_mask 
	FROM	glco
	WHERE	company_id = @company_id

	SELECT 	@gl_format = RTRIM(@gl_format) + "***"		

	SELECT 	@gl_mask_length	= CHARINDEX("***", @gl_format),
			@num_separators = 0

	IF @gl_mask_length = 0
		SELECT @gl_mask_length = 32
	ELSE
		SELECT @gl_mask_length = @gl_mask_length - 1

	SELECT 	@separator_pos = CHARINDEX( "-", @gl_format)
	WHILE	@separator_pos > 0
	BEGIN
		SELECT @num_separators 	= @num_separators + 1
		SELECT @gl_format 		= SUBSTRING(@gl_format, 1, @separator_pos - 1) + SUBSTRING(@gl_format, @separator_pos + 1, 32 - @separator_pos)
		SELECT @separator_pos 	= CHARINDEX( "-", @gl_format)
	END

	SELECT 	@gl_mask_length = @gl_mask_length - @num_separators
	
	
	SELECT 	@natural_acct		= acct_level,
			@start_natural		= start_col,
			@natural_format		= LTRIM(RTRIM(acct_format)) + "***"
	FROM	glaccdef
	WHERE	natural_acct_flag	= 1

	
	SELECT	@end_natural 		= @start_natural + (CHARINDEX("***", @natural_format) - 1) - 1

	
	SELECT 	@classification_id = MIN(classification_id)
	FROM 	inserted 

	WHILE @classification_id IS NOT NULL 
	BEGIN 
		SELECT 	@classification_name	= classification_name,
			 	@acct_level				= acct_level,
				@override_default		= override_default,
				@new_start_col			= start_col,
				@new_length				= length
		FROM 	inserted 
		WHERE 	company_id				= @company_id
		AND		classification_id 		= @classification_id 

		SELECT 	@start_col				= start_col,
				@length					= length
		FROM 	deleted 
		WHERE 	company_id				= @company_id
		AND		classification_id 		= @classification_id 
		
		
		IF (@new_start_col <> @start_col)
		OR (@new_length	<> @length)
		BEGIN
			
			IF EXISTS (	SELECT 	classification_code 
						FROM 	amcls 
						WHERE	company_id			= @company_id
						AND 	classification_id 	= @classification_id
					 )
			BEGIN
				EXEC 		amGetErrorMessage_sp 20011, ".\\amclshdr.utr", 214, @classification_name, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20011 @message 
				SELECT 		@rollback = 1 
			END
		END
		
		
		IF (@new_start_col + @new_length - 1 > @gl_mask_length)
		BEGIN
			EXEC 		amGetErrorMessage_sp 20131, ".\\amclshdr.utr", 226, @classification_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20131 @message 
			SELECT 		@rollback = 1 
		END
		
		
		SELECT @temp_str = RTRIM(@override_default) + "***"
		IF CHARINDEX("***", @temp_str) > 1
		BEGIN
			EXEC @error = amValidClsOverride_sp 
							@company_id, 
							@acct_level, 
							@new_start_col, 
							@new_length,
							@override_default,
							@valid OUTPUT
			IF (@valid = 0)
			BEGIN
				EXEC 		amGetErrorMessage_sp 20132, ".\\amclshdr.utr", 246, @override_default, @classification_name, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20132 @message 
				SELECT 		@rollback = 1 
			END
		END

		




		IF @acct_level = @natural_acct
		BEGIN
			EXEC 		amGetErrorMessage_sp 20133, ".\\amclshdr.utr", 261, @classification_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20133 @message 
			SELECT 		@rollback = 1 
		END
		ELSE
		BEGIN
			IF 	(@acct_level = 0)
			AND	(	(@new_start_col >= @start_natural AND @new_start_col <= @end_natural)
				OR	(@new_end_col >= @start_natural AND @new_end_col <= @end_natural))
			BEGIN
				EXEC 		amGetErrorMessage_sp 20133, ".\\amclshdr.utr", 271, @classification_name, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20133 @message 
				SELECT 		@rollback = 1 
			END
		END

		 
		SELECT 	@classification_id = MIN(classification_id)
		FROM 	inserted 
		WHERE 	classification_id > @classification_id 
	END			
END 

IF 	@rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END


GO
CREATE UNIQUE NONCLUSTERED INDEX [amclshdr_ind_1] ON [dbo].[amclshdr] ([company_id], [classification_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amclshdr_ind_0] ON [dbo].[amclshdr] ([company_id], [classification_name]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclshdr].[classification_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclshdr].[acct_level]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclshdr].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amclshdr].[created_by]'
GO
GRANT REFERENCES ON  [dbo].[amclshdr] TO [public]
GO
GRANT SELECT ON  [dbo].[amclshdr] TO [public]
GO
GRANT INSERT ON  [dbo].[amclshdr] TO [public]
GO
GRANT DELETE ON  [dbo].[amclshdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[amclshdr] TO [public]
GO
