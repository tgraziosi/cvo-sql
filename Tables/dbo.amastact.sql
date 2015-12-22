CREATE TABLE [dbo].[amastact]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[account_type_id] [dbo].[smAccountTypeID] NOT NULL,
[account_code] [dbo].[smAccountCode] NOT NULL,
[up_to_date] [dbo].[smLogical] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amastact_ind_0] ON [dbo].[amastact] ([co_asset_id], [account_type_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amastact].[co_asset_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amastact].[up_to_date]'
GO
GRANT REFERENCES ON  [dbo].[amastact] TO [public]
GO
GRANT SELECT ON  [dbo].[amastact] TO [public]
GO
GRANT INSERT ON  [dbo].[amastact] TO [public]
GO
GRANT DELETE ON  [dbo].[amastact] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastact] TO [public]
GO
