CREATE TABLE [dbo].[rpt_amastprf]
(
[current_cost_accum_depr] [float] NULL,
[fiscal_period_end] [datetime] NULL,
[current_cost] [float] NULL,
[accum_depr] [float] NULL,
[asset_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amastprf] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amastprf] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amastprf] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amastprf] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amastprf] TO [public]
GO
