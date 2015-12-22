CREATE TABLE [dbo].[amgrphdr]
(
[timestamp] [timestamp] NOT NULL,
[group_code] [dbo].[smGroupCode] NOT NULL,
[group_id] [dbo].[smSurrogateKey] NOT NULL,
[group_description] [dbo].[smStdDescription] NOT NULL,
[group_edited] [dbo].[smLogical] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amgrphdr_del_trg] 
ON 				[dbo].[amgrphdr] 
FOR 			DELETE 
AS 

DECLARE 
	@rowcount 		smCounter,
	@message		smErrorLongDesc

SELECT @rowcount = @@rowcount


 
DELETE 	amgrpdet 
FROM 	deleted d, 
		amgrpdet gd 
WHERE 	d.group_id 	= gd.group_id 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

 
DELETE 	amgrpast 
FROM 	deleted d, 
		amgrpast ga 
WHERE 	d.group_id 	= ga.group_id 

IF @@error <> 0 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END


GO
CREATE UNIQUE CLUSTERED INDEX [amgrphdr_ind_0] ON [dbo].[amgrphdr] ([group_code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amgrphdr_ind_1] ON [dbo].[amgrphdr] ([group_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amgrphdr].[group_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amgrphdr].[group_description]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amgrphdr].[group_edited]'
GO
GRANT REFERENCES ON  [dbo].[amgrphdr] TO [public]
GO
GRANT SELECT ON  [dbo].[amgrphdr] TO [public]
GO
GRANT INSERT ON  [dbo].[amgrphdr] TO [public]
GO
GRANT DELETE ON  [dbo].[amgrphdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[amgrphdr] TO [public]
GO
