CREATE TABLE [dbo].[amtmplcl]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[classification_id] [dbo].[smSurrogateKey] NOT NULL,
[template_code] [dbo].[smTemplateCode] NOT NULL,
[classification_code] [dbo].[smClassificationCode] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtmplcl_ins_trg] 
ON 				[dbo].[amtmplcl] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 






 


 
IF ( SELECT 	COUNT(i.template_code) 
		FROM 	inserted i, 
				amtmplas f 
		WHERE 	f.template_code = i.template_code) <> @rowcount 
BEGIN 



	EXEC 		amGetErrorMessage_sp 20583, ".\\amtmplcl.itr", 75, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20583 @message 
	SELECT 		@rollback = 1 
END 


 
IF ( SELECT COUNT(i.classification_code) 
		FROM 	inserted i, 
				amcls c 
		WHERE 	c.company_id 			= i.company_id
		AND		c.classification_id		= i.classification_id
		AND		c.classification_code 	= i.classification_code) <> @rowcount 
BEGIN 




	EXEC 		amGetErrorMessage_sp 20581, ".\\amtmplcl.itr", 93, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20581 @message 
	SELECT 		@rollback = 1 			 
END 


 
IF @rollback = 1 
BEGIN 



	ROLLBACK TRANSACTION 
	RETURN 
END 





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtmplcl_upd_trg] 
ON 				[dbo].[amtmplcl] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 		smCounter, 
	@keycount 		smCounter, 
	@rollback 		smLogical, 
	@message 		smErrorLongDesc

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 





 
SELECT 	@keycount 			= COUNT(i.classification_id) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.classification_id	= d.classification_id 
AND 	i.template_code		= d.template_code 






IF @keycount <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20584, ".\\amtmplcl.utr", 87, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20584 @message 
	SELECT 		@rollback = 1 
END 

 
IF UPDATE(classification_code)
BEGIN
	IF ( SELECT COUNT(i.company_id) 
			FROM 	inserted i, 
					amcls c 
			WHERE 	c.company_id 			= i.company_id
			AND		c.classification_id		= i.classification_id
			AND		c.classification_code 	= i.classification_code) <> @rowcount 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20582, ".\\amtmplcl.utr", 109, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20582 @message 
		SELECT 		@rollback = 1 			 
	END 
END

 
IF @rollback = 1 
BEGIN 



	ROLLBACK TRANSACTION 
	RETURN 
END 





GO
CREATE UNIQUE CLUSTERED INDEX [amtmplcl_ind_0] ON [dbo].[amtmplcl] ([company_id], [classification_id], [template_code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amtmplcl_ind_1] ON [dbo].[amtmplcl] ([template_code], [company_id], [classification_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplcl].[classification_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplcl].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amtmplcl] TO [public]
GO
GRANT SELECT ON  [dbo].[amtmplcl] TO [public]
GO
GRANT INSERT ON  [dbo].[amtmplcl] TO [public]
GO
GRANT DELETE ON  [dbo].[amtmplcl] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtmplcl] TO [public]
GO
