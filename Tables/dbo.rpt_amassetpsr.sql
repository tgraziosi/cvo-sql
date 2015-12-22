CREATE TABLE [dbo].[rpt_amassetpsr]
(
[delta_cost] [float] NOT NULL,
[asset_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[placed_in_service_date] [datetime] NOT NULL,
[disposition_date] [datetime] NOT NULL,
[status_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[depr_rule_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[convention_id] [tinyint] NOT NULL,
[book_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[proceeds] [float] NOT NULL,
[gain_loss] [float] NOT NULL,
[delta_accum_depr] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassetpsr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassetpsr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassetpsr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassetpsr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassetpsr] TO [public]
GO
