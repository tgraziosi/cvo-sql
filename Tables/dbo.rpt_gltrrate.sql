CREATE TABLE [dbo].[rpt_gltrrate]
(
[timestamp] [timestamp] NOT NULL,
[override_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_comp_id] [smallint] NOT NULL,
[all_comp_flag] [smallint] NOT NULL,
[consol_type] [smallint] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_type] [smallint] NOT NULL,
[date] [int] NULL,
[override_rate] [float] NOT NULL,
[override_rate_oper] [float] NOT NULL,
[consol_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gltrrate] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gltrrate] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gltrrate] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gltrrate] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gltrrate] TO [public]
GO
