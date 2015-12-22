CREATE TABLE [dbo].[amas3]
(
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[co_asset_book_id] [dbo].[smSurrogateKey] NOT NULL,
[book_code] [dbo].[smBookCode] NOT NULL,
[orig_salvage_value] [dbo].[smMoneyZero] NOT NULL,
[date_placed_in_service] [dbo].[smApplyDate] NULL,
[date_last_posted_depr] [dbo].[smApplyDate] NULL,
[x_orig_salvage_value] [dbo].[smMoneyZero] NOT NULL,
[x_date_placed_in_service] [dbo].[smApplyDate] NULL,
[x_date_last_posted_depr] [dbo].[smApplyDate] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amas3_ind_0] ON [dbo].[amas3] ([co_asset_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas3].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas3].[co_asset_book_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas3].[orig_salvage_value]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas3].[x_orig_salvage_value]'
GO
GRANT REFERENCES ON  [dbo].[amas3] TO [public]
GO
GRANT SELECT ON  [dbo].[amas3] TO [public]
GO
GRANT INSERT ON  [dbo].[amas3] TO [public]
GO
GRANT DELETE ON  [dbo].[amas3] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas3] TO [public]
GO
