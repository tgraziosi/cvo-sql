CREATE TABLE [dbo].[rpt_gltrx_db_name]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[db_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gltrx_db_name] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gltrx_db_name] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gltrx_db_name] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gltrx_db_name] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gltrx_db_name] TO [public]
GO
