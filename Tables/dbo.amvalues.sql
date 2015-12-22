CREATE TABLE [dbo].[amvalues]
(
[timestamp] [timestamp] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[account_type_id] [dbo].[smAccountTypeID] NOT NULL,
[apply_date] [dbo].[smApplyDate] NOT NULL,
[trx_type] [dbo].[smTrxType] NOT NULL,
[amount] [dbo].[smMoneyZero] NOT NULL,
[account_id] [dbo].[smSurrogateKey] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amvalues_ind_2] ON [dbo].[amvalues] ([account_id]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amvalues_ind_1] ON [dbo].[amvalues] ([apply_date]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amvalues_ind_4] ON [dbo].[amvalues] ([co_asset_book_id], [account_type_id], [trx_type]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amvalues_ind_0] ON [dbo].[amvalues] ([co_trx_id], [co_asset_book_id], [account_type_id]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amvalues_ind_3] ON [dbo].[amvalues] ([trx_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amvalues].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amvalues].[co_asset_book_id]'
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amvalues].[trx_type]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amvalues].[amount]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amvalues].[account_id]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[amvalues].[posting_flag]'
GO
GRANT REFERENCES ON  [dbo].[amvalues] TO [public]
GO
GRANT SELECT ON  [dbo].[amvalues] TO [public]
GO
GRANT INSERT ON  [dbo].[amvalues] TO [public]
GO
GRANT DELETE ON  [dbo].[amvalues] TO [public]
GO
GRANT UPDATE ON  [dbo].[amvalues] TO [public]
GO
