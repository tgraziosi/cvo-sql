CREATE TABLE [dbo].[rpt_ampendfor]
(
[nend_accum_depr] [float] NULL,
[end_cost_end_accum_depr] [float] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amtrxhdr_apply_date] [datetime] NULL,
[amcalval_apply_date] [datetime] NULL,
[co_asset_id] [int] NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_cost] [float] NULL,
[end_accum_depr] [float] NULL,
[amount] [float] NULL,
[year_end_date] [datetime] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ampendfor] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ampendfor] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ampendfor] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ampendfor] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ampendfor] TO [public]
GO
