CREATE TABLE [dbo].[ammasast]
(
[timestamp] [timestamp] NOT NULL,
[mass_maintenance_id] [dbo].[smSurrogateKey] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[error_code] [dbo].[smErrorCode] NOT NULL,
[error_message] [dbo].[smErrorLongDesc] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ammasast_ind_0] ON [dbo].[ammasast] ([mass_maintenance_id], [company_id], [asset_ctrl_num]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammasast].[mass_maintenance_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammasast].[co_asset_id]'
GO
GRANT REFERENCES ON  [dbo].[ammasast] TO [public]
GO
GRANT SELECT ON  [dbo].[ammasast] TO [public]
GO
GRANT INSERT ON  [dbo].[ammasast] TO [public]
GO
GRANT DELETE ON  [dbo].[ammasast] TO [public]
GO
GRANT UPDATE ON  [dbo].[ammasast] TO [public]
GO
