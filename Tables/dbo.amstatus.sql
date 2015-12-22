CREATE TABLE [dbo].[amstatus]
(
[timestamp] [timestamp] NOT NULL,
[status_code] [dbo].[smStatusCode] NOT NULL,
[status_description] [dbo].[smStdDescription] NOT NULL,
[activity_state] [dbo].[smUserState] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amstatus_del_trg] 
ON 				[dbo].[amstatus] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@status_code	smStatusCode,
	@asset_ctrl_num	smControlNumber,
	@template_code	smTemplateCode

SELECT @rollback 	= 0 

 
SELECT	@status_code = MIN(status_code)
FROM	deleted

WHILE @status_code IS NOT NULL
BEGIN
	SELECT	@asset_ctrl_num = NULL
	
	SELECT	@asset_ctrl_num = MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	status_code		= @status_code
	
	IF @asset_ctrl_num IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20534, ".\\amstatus.dtr", 98, @status_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20534 @message 
		SELECT 		@rollback = 1 
	END 

	IF @rollback = 0
	BEGIN
		SELECT	@template_code 	= MIN(template_code)
		FROM	amtmplas
		WHERE	status_code		= @status_code
		
		IF @template_code IS NOT NULL 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20566, ".\\amstatus.dtr", 111, @status_code, @template_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20566 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@status_code 	= MIN(status_code)
	FROM	deleted
	WHERE	status_code		> @status_code

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amstatus_upd_trg] 
ON 				[dbo].[amstatus] 
FOR 			UPDATE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@rowcount 		smCounter, 
	@keycount 		smCounter, 
	@message 		smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount = COUNT(i.status_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.status_code = d.status_code 

IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20533, ".\\amstatus.utr", 93, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20533 @message 
	SELECT 		@rollback = 1 
END 


IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amstatus_ind_0] ON [dbo].[amstatus] ([status_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amstatus].[status_description]'
GO
EXEC sp_bindrule N'[dbo].[smUserState_rl]', N'[dbo].[amstatus].[activity_state]'
GO
EXEC sp_bindefault N'[dbo].[smUserState_df]', N'[dbo].[amstatus].[activity_state]'
GO
GRANT REFERENCES ON  [dbo].[amstatus] TO [public]
GO
GRANT SELECT ON  [dbo].[amstatus] TO [public]
GO
GRANT INSERT ON  [dbo].[amstatus] TO [public]
GO
GRANT DELETE ON  [dbo].[amstatus] TO [public]
GO
GRANT UPDATE ON  [dbo].[amstatus] TO [public]
GO
