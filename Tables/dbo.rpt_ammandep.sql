CREATE TABLE [dbo].[rpt_ammandep]
(
[co_asset_id] [int] NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_book_id] [int] NULL,
[fiscal_period_end] [datetime] NULL,
[depr_expense] [float] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ammandep] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ammandep] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ammandep] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ammandep] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ammandep] TO [public]
GO
