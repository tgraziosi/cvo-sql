CREATE TABLE [dbo].[amemp]
(
[timestamp] [timestamp] NOT NULL,
[employee_code] [dbo].[smEmployeeCode] NOT NULL,
[employee_name] [dbo].[smStdDescription] NOT NULL,
[job_title] [dbo].[smStdDescription] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amemp_del_trg] 
ON 				[dbo].[amemp] 
FOR 			DELETE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@employee_code 	smEmployeeCode,
	@asset_ctrl_num	smControlNumber,
	@template_code	smTemplateCode
	 
SELECT @rollback = 0 

SELECT	@employee_code = MIN(employee_code)
FROM	deleted

WHILE @employee_code IS NOT NULL
BEGIN
	SELECT	@asset_ctrl_num = NULL,
			@template_code	= NULL
	
	SELECT	@asset_ctrl_num = MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	employee_code	= @employee_code
	
	IF @asset_ctrl_num IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20530, ".\\amemp.dtr", 99, @employee_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20530 @message 
		SELECT 		@rollback = 1 
	END 

	

	IF @rollback = 0
	BEGIN
		SELECT	@template_code 	= MIN(template_code)
		FROM	amtmplas
		WHERE	employee_code	= @employee_code
		
		IF @template_code IS NOT NULL 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20564, ".\\amemp.dtr", 114, @employee_code, @template_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20564 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@employee_code 	= MIN(employee_code)
	FROM	deleted
	WHERE	employee_code	> @employee_code

END
IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER	[dbo].[amemp_upd_trg] 
ON 				[dbo].[amemp] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@keycount 		smCounter, 
	@numrows 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount = COUNT(i.employee_code)
FROM 	deleted d,
		inserted i 
WHERE 	d.employee_code = i.employee_code 

IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20529, ".\\amemp.utr", 87, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20529 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 

GO
CREATE UNIQUE CLUSTERED INDEX [amemp_ind_0] ON [dbo].[amemp] ([employee_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amemp].[employee_name]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amemp].[job_title]'
GO
GRANT REFERENCES ON  [dbo].[amemp] TO [public]
GO
GRANT SELECT ON  [dbo].[amemp] TO [public]
GO
GRANT INSERT ON  [dbo].[amemp] TO [public]
GO
GRANT DELETE ON  [dbo].[amemp] TO [public]
GO
GRANT UPDATE ON  [dbo].[amemp] TO [public]
GO
