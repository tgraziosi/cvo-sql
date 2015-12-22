CREATE TABLE [dbo].[rpt_amsumfuldep]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_rule_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salvage_value] [float] NULL,
[current_cost] [float] NULL,
[accum_depr] [float] NULL,
[book_value] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amsumfuldep] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amsumfuldep] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amsumfuldep] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amsumfuldep] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amsumfuldep] TO [public]
GO
