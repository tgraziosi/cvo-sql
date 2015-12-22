CREATE TABLE [dbo].[rpt_glconrecdet]
(
[timestamp] [timestamp] NOT NULL,
[detail_type] [smallint] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[parent_acct_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_journal_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[natural_amt] [float] NOT NULL,
[transl_type] [smallint] NOT NULL,
[rate] [float] NOT NULL,
[transl_amt] [float] NOT NULL,
[parent_acct_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_acct_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_oper] [float] NOT NULL,
[transl_amt_oper] [float] NOT NULL,
[db_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glconrecdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glconrecdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glconrecdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glconrecdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glconrecdet] TO [public]
GO
