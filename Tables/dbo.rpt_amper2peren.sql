CREATE TABLE [dbo].[rpt_amper2peren]
(
[report_group] [tinyint] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [int] NULL,
[classification_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_subgroup] [tinyint] NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type] [tinyint] NULL,
[start_value] [float] NULL,
[addition] [float] NULL,
[improvements] [float] NULL,
[revaluation] [float] NULL,
[adjustment] [float] NULL,
[impairment] [float] NULL,
[disposition] [float] NULL,
[depreciation] [float] NULL,
[end_value] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amper2peren] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amper2peren] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amper2peren] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amper2peren] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amper2peren] TO [public]
GO
