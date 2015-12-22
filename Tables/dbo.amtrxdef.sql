CREATE TABLE [dbo].[amtrxdef]
(
[timestamp] [timestamp] NOT NULL,
[trx_type] [dbo].[smTrxType] NOT NULL,
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[create_activity] [dbo].[smCounter] NOT NULL,
[display_activity] [dbo].[smLogicalTrue] NOT NULL,
[display_in_reports] [dbo].[smCounter] NOT NULL,
[effective_date_type] [dbo].[smCounter] NOT NULL,
[copy_trx_on_replicate] [dbo].[smLogicalTrue] NOT NULL,
[allow_to_import] [dbo].[smLogicalTrue] NOT NULL,
[prd_to_prd_column] [dbo].[smCounter] NOT NULL,
[post_to_gl] [dbo].[smLogicalTrue] NOT NULL,
[summmarize_activity] [dbo].[smLogicalFalse] NOT NULL,
[trx_name] [dbo].[smName] NOT NULL,
[trx_short_name] [dbo].[smName] NOT NULL,
[trx_description] [dbo].[smStdDescription] NOT NULL,
[last_updated] [dbo].[smApplyDate] NOT NULL,
[updated_by] [dbo].[smUserID] NOT NULL,
[date_created] [dbo].[smApplyDate] NOT NULL,
[created_by] [dbo].[smUserID] NOT NULL,
[system_only] [dbo].[smLogicalFalse] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtrxdef_del_trg] 
ON 				[dbo].[amtrxdef] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@param			smErrorParam,
	@trx_type		smTrxType,
	@trx_name		smName,
	@gl_trx_type	int
 
SELECT @rollback 	= 0 

SELECT	@trx_type = MIN(trx_type)
FROM	deleted

WHILE @trx_type IS NOT NULL
BEGIN
	
	IF EXISTS (SELECT	trx_type 
				FROM	amtrxhdr
				WHERE	trx_type = @trx_type)
	BEGIN 

		SELECT		@trx_name = trx_name
		FROM		amtrxdef
		WHERE		trx_type = @trx_type

		EXEC 		amGetErrorMessage_sp 20589, ".\\amtrxdef.dtr", 80, @trx_name, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20589 @message 
		SELECT 		@rollback = 1 
	END 

	
	
	
	DELETE	amtrxact
	WHERE	trx_type = @trx_type
	
	IF @@error <> 0 
	BEGIN
		SELECT		@trx_name = trx_name
		FROM		amtrxdef
		WHERE		trx_type = @trx_type

		EXEC 		amGetErrorMessage_sp 20592, ".\\amtrxdef.dtr", 99, @trx_name, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20592 @message 
		SELECT 		@rollback = 1 
	END


	SELECT @gl_trx_type = 10000 + @trx_type

	IF EXISTS(SELECT trx_type FROM gltrxtyp WHERE trx_type = @gl_trx_type)
	BEGIN

		
		DELETE	gltrxtyp
		WHERE	trx_type = @gl_trx_type	

		IF @@error <> 0 
		BEGIN

			SELECT		@trx_name = trx_name
			FROM		amtrxdef
			WHERE		trx_type = @trx_type

		 	EXEC 		amGetErrorMessage_sp 20593, ".\\amtrxdef.dtr", 123, @trx_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20593 @message 
			SELECT 		@rollback = 1
			 
		END

	END


 	
			 
	
	SELECT	@trx_type 	= MIN(trx_type)
	FROM	deleted
	WHERE	trx_type		> @trx_type

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtrxdef_ins_trg] 
ON 				[dbo].[amtrxdef] 
FOR 			INSERT
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@param			smErrorParam,
	@trx_type		smTrxType,
	@trx_name		smName,
	@gl_trx_type	int,
	@gl_trx_desc varchar(40),
	@gl_trx_code char(8)
 
SELECT @rollback 	= 0 

SELECT	@trx_type = MIN(trx_type)
FROM	inserted

WHILE @trx_type IS NOT NULL
BEGIN
	
	

	SELECT 	@gl_trx_type = 10000 + @trx_type,
	 		@gl_trx_desc = "AM " + trx_name,
			@gl_trx_code = "AM " + CONVERT(char(3),@trx_type)

	FROM 	inserted
	WHERE	trx_type 	 = @trx_type

	IF NOT EXISTS(SELECT trx_type FROM gltrxtyp WHERE trx_type = @gl_trx_type)
	BEGIN

		
		INSERT	gltrxtyp(trx_type,trx_type_desc,trx_type_code)
		VALUES (@gl_trx_type,@gl_trx_desc,@gl_trx_code)
			

		IF @@error <> 0 
		BEGIN

			SELECT		@trx_name = trx_name
			FROM		inserted
			WHERE		trx_type = @trx_type

		 	EXEC 		amGetErrorMessage_sp 20594, ".\\amtrxdef.itr", 99, @trx_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20594 @message 
			SELECT 		@rollback = 1
			 
		END

	END


 	
			 
	
	SELECT	@trx_type 	= MIN(trx_type)
	FROM	inserted
	WHERE	trx_type		> @trx_type

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtrxdef_upd_trg] 
ON 				[dbo].[amtrxdef] 
FOR 			UPDATE
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@param			smErrorParam,
	@new_trx_type 	int,
	@old_trx_type 	int,
	@trx_name		smName,
	@system_defined smLogical,
	@gl_trx_code	char(8)

SELECT @rollback 	= 0 

SELECT	@trx_name = MIN(trx_name)
FROM	deleted

WHILE @trx_name IS NOT NULL
BEGIN

	 

	
	SELECT 	@new_trx_type 	= trx_type
	FROM	inserted
	WHERE	@trx_name 		= trx_name

	SELECT 	@old_trx_type 	= trx_type
	FROM	deleted
	WHERE	@trx_name 		= trx_name

	IF @new_trx_type <> @old_trx_type
	BEGIN

		

		
		IF EXISTS (SELECT	trx_type 
				 FROM		amtrxhdr
				 WHERE	trx_type = @old_trx_type)
		BEGIN 

	 
			EXEC 		amGetErrorMessage_sp 20589, ".\\amtrxdef.utr", 94, @trx_name, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20589 @message 
			SELECT 		@rollback = 1 
		END

		UPDATE	amtrxact
		SET		trx_type	= @new_trx_type
		WHERE	trx_type	= @old_trx_type
		
		IF @@error <> 0 
		BEGIN

		 	EXEC 		amGetErrorMessage_sp 20595, ".\\amtrxdef.utr", 106, "amtrxact", @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20595 @message 
			SELECT 		@rollback = 1 
		END
		
		
		SELECT 	@gl_trx_code = "AM " + CONVERT(char(3),@new_trx_type)

		SELECT	@new_trx_type = 10000 + @new_trx_type,
			 	@old_trx_type = 10000 + @old_trx_type

	 IF EXISTS(SELECT trx_type FROM gltrxtyp WHERE trx_type = @old_trx_type)
		BEGIN

			UPDATE	gltrxtyp
			SET		trx_type		= @new_trx_type,
				 trx_type_code 	= @gl_trx_code
			WHERE	trx_type		= @old_trx_type
			
			IF @@error <> 0 
			BEGIN

			 	EXEC 		amGetErrorMessage_sp 20595, ".\\amtrxdef.utr", 128, "gltrxtyp", @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20595 @message 
				SELECT 		@rollback = 1 
			END

 		END
	
	END


				 
	
	SELECT	@trx_name 	= MIN(trx_name)
	FROM	inserted
	WHERE	trx_name		> @trx_name

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amtrxdef_ind_0] ON [dbo].[amtrxdef] ([trx_name]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amtrxdef_ind_1] ON [dbo].[amtrxdef] ([trx_type]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amtrxdef].[trx_type]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxdef].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxdef].[create_activity]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[display_activity]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtrxdef].[display_activity]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxdef].[display_in_reports]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxdef].[effective_date_type]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[copy_trx_on_replicate]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtrxdef].[copy_trx_on_replicate]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[allow_to_import]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtrxdef].[allow_to_import]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxdef].[prd_to_prd_column]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[post_to_gl]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtrxdef].[post_to_gl]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[summmarize_activity]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxdef].[summmarize_activity]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtrxdef].[trx_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxdef].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxdef].[created_by]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxdef].[system_only]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxdef].[system_only]'
GO
GRANT REFERENCES ON  [dbo].[amtrxdef] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxdef] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxdef] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxdef] TO [public]
GO
