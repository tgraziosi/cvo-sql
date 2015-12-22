CREATE TABLE [dbo].[amcalval]
(
[timestamp] [timestamp] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[apply_date] [dbo].[smApplyDate] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[book_code] [dbo].[smBookCode] NOT NULL,
[placed_in_service_date] [dbo].[smApplyDate] NOT NULL,
[beg_cost] [dbo].[smMoneyZero] NOT NULL,
[beg_accum_depr] [dbo].[smMoneyZero] NOT NULL,
[end_cost] [dbo].[smMoneyZero] NOT NULL,
[end_accum_depr] [dbo].[smMoneyZero] NOT NULL,
[account_reference_code] [dbo].[smAccountReferenceCode] NOT NULL,
[depr_exp_account] [dbo].[smAccountCode] NOT NULL,
[accum_depr_account] [dbo].[smAccountCode] NOT NULL,
[amount] [dbo].[smMoneyZero] NOT NULL,
[year_end_date] [dbo].[smApplyDate] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amcalval_ind_0] ON [dbo].[amcalval] ([co_trx_id], [co_asset_book_id], [apply_date]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[co_asset_book_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[beg_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[beg_accum_depr]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[end_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[end_accum_depr]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amcalval].[account_reference_code]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amcalval].[amount]'
GO
GRANT REFERENCES ON  [dbo].[amcalval] TO [public]
GO
GRANT SELECT ON  [dbo].[amcalval] TO [public]
GO
GRANT INSERT ON  [dbo].[amcalval] TO [public]
GO
GRANT DELETE ON  [dbo].[amcalval] TO [public]
GO
GRANT UPDATE ON  [dbo].[amcalval] TO [public]
GO
