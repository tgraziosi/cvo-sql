CREATE TABLE [dbo].[rpt_amassettag]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [int] NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_tag] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassettag] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassettag] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassettag] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassettag] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassettag] TO [public]
GO
