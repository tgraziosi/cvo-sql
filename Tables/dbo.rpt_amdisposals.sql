CREATE TABLE [dbo].[rpt_amdisposals]
(
[asset_type_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_ctrl_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_service_date] [datetime] NULL,
[disposition_date] [datetime] NULL,
[cost_close_bal] [float] NULL,
[depr_open_bal] [float] NULL,
[open_wdv] [float] NULL,
[prd_accum_depr] [float] NULL,
[accum_depr_on_disp] [float] NULL,
[book_value_on_disp] [float] NULL,
[proceeds] [float] NULL,
[profit] [float] NULL,
[loss] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amdisposals] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amdisposals] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amdisposals] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amdisposals] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amdisposals] TO [public]
GO
