CREATE TABLE [dbo].[rpt_amsales]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acquisition_date] [datetime] NULL,
[disposition_date] [datetime] NULL,
[proceeds] [float] NULL,
[gain_loss] [float] NULL,
[classification_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[delta_cost] [float] NULL,
[delta_accum_depr] [float] NULL,
[amount] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amsales] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amsales] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amsales] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amsales] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amsales] TO [public]
GO
