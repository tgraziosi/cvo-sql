CREATE TABLE [dbo].[rpt_amdprrul]
(
[depr_rule_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rule_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[depr_method_id] [smallint] NOT NULL,
[convention_id] [tinyint] NOT NULL,
[service_life] [float] NOT NULL,
[useful_life_end_date] [datetime] NULL,
[annual_depr_rate] [float] NOT NULL,
[def_salvage_percent] [float] NOT NULL,
[def_salvage_value] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amdprrul] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amdprrul] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amdprrul] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amdprrul] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amdprrul] TO [public]
GO
