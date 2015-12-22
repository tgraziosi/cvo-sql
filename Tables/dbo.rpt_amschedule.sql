CREATE TABLE [dbo].[rpt_amschedule]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_rule_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rule_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_method_id] [smallint] NULL,
[convention_id] [tinyint] NULL,
[annual_depr_rate] [float] NULL,
[recovery_period] [float] NULL,
[placed_in_service_date] [datetime] NULL,
[salvage_value] [float] NULL,
[business_usage] [float] NULL,
[ending_cost] [float] NULL,
[ending_accum_depr] [float] NULL,
[depr_expense] [float] NULL,
[business_cost] [float] NULL,
[business_depr_exp] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amschedule] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amschedule] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amschedule] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amschedule] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amschedule] TO [public]
GO
