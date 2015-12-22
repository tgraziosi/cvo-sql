CREATE TABLE [dbo].[rpt_amper2perabb]
(
[classification_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_rule_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_cost] [float] NULL,
[beg_accum_depr] [float] NULL,
[ytd_accum_depr] [float] NULL,
[ytd_depr_exp] [float] NULL,
[book_value] [float] NULL,
[co_asset_id] [int] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amper2perabb] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amper2perabb] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amper2perabb] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amper2perabb] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amper2perabb] TO [public]
GO
