CREATE TABLE [dbo].[amas4]
(
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[account_code] [dbo].[smAccountCode] NOT NULL,
[up_to_date] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type_description] [dbo].[smStdDescription] NOT NULL,
[date_last_modified] [dbo].[smApplyDate] NOT NULL,
[x_date_last_modified] [dbo].[smApplyDate] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amas4_ind_0] ON [dbo].[amas4] ([co_asset_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas4].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas4].[account_type_description]'
GO
GRANT REFERENCES ON  [dbo].[amas4] TO [public]
GO
GRANT SELECT ON  [dbo].[amas4] TO [public]
GO
GRANT INSERT ON  [dbo].[amas4] TO [public]
GO
GRANT DELETE ON  [dbo].[amas4] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas4] TO [public]
GO
