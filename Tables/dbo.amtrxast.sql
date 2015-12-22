CREATE TABLE [dbo].[amtrxast]
(
[timestamp] [timestamp] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[org_id] [dbo].[smOrgId] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amtrxast_ind_1] ON [dbo].[amtrxast] ([co_trx_id], [co_asset_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amtrxast_ind_0] ON [dbo].[amtrxast] ([co_trx_id], [company_id], [asset_ctrl_num]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxast].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxast].[co_asset_id]'
GO
GRANT REFERENCES ON  [dbo].[amtrxast] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxast] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxast] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxast] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxast] TO [public]
GO
