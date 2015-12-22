CREATE TABLE [dbo].[amastchg]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[field_type] [dbo].[smFieldType] NOT NULL,
[apply_date] [dbo].[smApplyDate] NOT NULL,
[old_value] [dbo].[smFieldData] NULL,
[new_value] [dbo].[smFieldData] NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[amastchg_ins_trg] 
ON 		[dbo].[amastchg] 
FOR 	INSERT AS 

DECLARE 
	@rowcount 	smCounter, 
	@rollback 	smLogical, 
	@message 	smErrorLongDesc 

SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
IF ( SELECT COUNT(i.co_asset_id) 
		FROM 	inserted i, 
				amasset f 
		WHERE 	f.co_asset_id = i.co_asset_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20556, ".\\amastchg.itr", 82, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20556 @message 
	SELECT 		@rollback = 1 
END 

IF @rollback = 1 
	ROLLBACK TRANSACTION 
GO
CREATE CLUSTERED INDEX [amastchg_ind_0] ON [dbo].[amastchg] ([co_asset_id], [field_type], [apply_date]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastchg].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amastchg].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastchg].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amastchg] TO [public]
GO
GRANT SELECT ON  [dbo].[amastchg] TO [public]
GO
GRANT INSERT ON  [dbo].[amastchg] TO [public]
GO
GRANT DELETE ON  [dbo].[amastchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastchg] TO [public]
GO
