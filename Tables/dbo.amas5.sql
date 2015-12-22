CREATE TABLE [dbo].[amas5]
(
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[trx_type] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_flag] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_apply] [dbo].[smApplyDate] NOT NULL,
[date_last_modified] [dbo].[smApplyDate] NOT NULL,
[date_posted] [dbo].[smApplyDate] NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[key_type] [int] NULL,
[key_1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_date_apply] [dbo].[smApplyDate] NOT NULL,
[x_date_last_modified] [dbo].[smApplyDate] NOT NULL,
[x_date_posted] [dbo].[smApplyDate] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amas5_ind_0] ON [dbo].[amas5] ([co_asset_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas5].[co_asset_id]'
GO
GRANT REFERENCES ON  [dbo].[amas5] TO [public]
GO
GRANT SELECT ON  [dbo].[amas5] TO [public]
GO
GRANT INSERT ON  [dbo].[amas5] TO [public]
GO
GRANT DELETE ON  [dbo].[amas5] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas5] TO [public]
GO
