CREATE TABLE [dbo].[rpt_ampenddep]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type_id] [smallint] NULL,
[apply_date] [datetime] NULL,
[trx_type] [dbo].[smTrxType] NULL,
[amount] [float] NULL,
[credit] [float] NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abs_amount] [float] NULL,
[co_trx_id] [dbo].[smSurrogateKey] NULL,
[trx_short_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[rpt_ampenddep].[trx_type]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[rpt_ampenddep].[co_trx_id]'
GO
GRANT REFERENCES ON  [dbo].[rpt_ampenddep] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ampenddep] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ampenddep] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ampenddep] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ampenddep] TO [public]
GO
