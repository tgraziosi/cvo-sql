CREATE TABLE [dbo].[rpt_ampurasset]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_state] [int] NULL,
[mass_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_created] [datetime] NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acquisition_date] [datetime] NULL,
[disposition_date] [datetime] NULL,
[original_cost] [float] NULL,
[lp_fiscal_period_end] [datetime] NULL,
[lp_accum_depr] [float] NULL,
[lp_current_cost] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ampurasset] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ampurasset] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ampurasset] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ampurasset] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ampurasset] TO [public]
GO
