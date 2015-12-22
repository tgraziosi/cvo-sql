CREATE TABLE [dbo].[rpt_amregister]
(
[asset_ctrl_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_service_date] [datetime] NULL,
[location_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[annual_depr_rate] [float] NULL,
[depr_method_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_rule_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost_close_bal] [float] NULL,
[depr_open_bal] [float] NULL,
[prd_accum_depr] [float] NULL,
[depr_close_bal] [float] NULL,
[close_wdv] [float] NULL,
[asset_type_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_ctrl_num1] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_ctrl_num2] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_start] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_imported] [int] NOT NULL,
[activity_state] [int] NOT NULL,
[activity_state_selected] [int] NOT NULL,
[convention_id] [int] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amregister] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amregister] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amregister] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amregister] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amregister] TO [public]
GO
