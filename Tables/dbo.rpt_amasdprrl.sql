CREATE TABLE [dbo].[rpt_amasdprrl]
(
[co_asset_id] [int] NOT NULL,
[co_asset_book_id] [int] NOT NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[placed_in_service_date] [datetime] NULL,
[effective_date] [datetime] NOT NULL,
[depr_rule_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salvage_value] [float] NOT NULL,
[end_life_date] [datetime] NOT NULL,
[book_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amasdprrl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amasdprrl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amasdprrl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amasdprrl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amasdprrl] TO [public]
GO
