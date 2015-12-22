CREATE TABLE [dbo].[rpt_amaspcs]
(
[current_cost] [float] NULL,
[accum_depr] [float] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_state] [int] NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_pledged] [int] NULL,
[lease_type] [int] NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_book_id] [int] NULL,
[depr_rule_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salvage_value] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amaspcs] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amaspcs] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amaspcs] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amaspcs] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amaspcs] TO [public]
GO
