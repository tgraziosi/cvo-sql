CREATE TABLE [dbo].[rpt_glcon]
(
[consol_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_asof] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[status_type] [smallint] NOT NULL,
[direct_post_flag] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[subs_id] [smallint] NOT NULL,
[subs_period_end_date] [int] NOT NULL,
[work_flag] [smallint] NOT NULL,
[sub_company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glcon] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glcon] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glcon] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glcon] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glcon] TO [public]
GO
