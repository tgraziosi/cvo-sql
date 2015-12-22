CREATE TABLE [dbo].[amloc]
(
[timestamp] [timestamp] NOT NULL,
[location_code] [dbo].[smLocationCode] NOT NULL,
[location_description] [dbo].[smStdDescription] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amloc_del_trg] 
ON 				[dbo].[amloc] 
FOR 			DELETE 
AS 


DECLARE 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc, 
	@location_code	smLocationCode,
	@asset_ctrl_num	smControlNumber,
	@template_code	smTemplateCode

SELECT @rollback 	= 0 

SELECT	@location_code = MIN(location_code)
FROM	deleted

WHILE @location_code IS NOT NULL
BEGIN
	SELECT	@asset_ctrl_num = NULL
	
	SELECT	@asset_ctrl_num = MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	location_code	= @location_code
	
	IF @asset_ctrl_num IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20532, ".\\amloc.dtr", 99, @location_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20532 @message 
		SELECT 		@rollback = 1 
	END 

	IF @rollback = 0
	BEGIN
		SELECT	@template_code	= MIN(template_code)
		FROM	amtmplas
		WHERE	location_code	= @location_code
		
		IF @template_code IS NOT NULL 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20565, ".\\amloc.dtr", 112, @location_code, @template_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20565 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@location_code 	= MIN(location_code)
	FROM	deleted
	WHERE	location_code	> @location_code

END

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amloc_upd_trg] 
ON 				[dbo].[amloc] 
FOR 			UPDATE 
AS 

DECLARE 
	@rollback 		smLogical, 
	@rowcount 		smCounter, 
	@keycount 		smCounter, 
	@message 		smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount = COUNT(i.location_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.location_code = d.location_code 

IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20531, ".\\amloc.utr", 92, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20531 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE UNIQUE CLUSTERED INDEX [amloc_ind_0] ON [dbo].[amloc] ([location_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amloc].[location_description]'
GO
GRANT REFERENCES ON  [dbo].[amloc] TO [public]
GO
GRANT SELECT ON  [dbo].[amloc] TO [public]
GO
GRANT INSERT ON  [dbo].[amloc] TO [public]
GO
GRANT DELETE ON  [dbo].[amloc] TO [public]
GO
GRANT UPDATE ON  [dbo].[amloc] TO [public]
GO
