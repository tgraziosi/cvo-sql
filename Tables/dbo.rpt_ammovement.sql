CREATE TABLE [dbo].[rpt_ammovement]
(
[type_code_id] [int] NULL,
[asset_type_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_ctrl_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type] [smallint] NULL,
[start_value] [float] NULL,
[addition] [float] NULL,
[improvement] [float] NULL,
[impairment] [float] NULL,
[revaluation] [float] NULL,
[adjustment] [float] NULL,
[disposition] [float] NULL,
[depreciation] [float] NULL,
[end_value] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ammovement] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ammovement] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ammovement] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ammovement] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ammovement] TO [public]
GO
