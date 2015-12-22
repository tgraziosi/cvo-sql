CREATE TABLE [dbo].[amgrpast]
(
[timestamp] [timestamp] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[group_id] [dbo].[smSurrogateKey] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amgrpast_ind_0] ON [dbo].[amgrpast] ([modified_by], [group_id], [company_id], [asset_ctrl_num]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amgrpast].[modified_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amgrpast].[group_id]'
GO
GRANT REFERENCES ON  [dbo].[amgrpast] TO [public]
GO
GRANT SELECT ON  [dbo].[amgrpast] TO [public]
GO
GRANT INSERT ON  [dbo].[amgrpast] TO [public]
GO
GRANT DELETE ON  [dbo].[amgrpast] TO [public]
GO
GRANT UPDATE ON  [dbo].[amgrpast] TO [public]
GO
