CREATE TABLE [dbo].[rpt_gledit_summary]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[e_code] [int] NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_level] [int] NOT NULL,
[info1] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gledit_summary] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gledit_summary] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gledit_summary] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gledit_summary] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gledit_summary] TO [public]
GO
