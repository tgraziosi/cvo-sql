CREATE TABLE [dbo].[rpt_aprptvaa]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_aging_old] [datetime] NULL,
[date_aging_new] [datetime] NULL,
[date_due_old] [datetime] NULL,
[date_due_new] [datetime] NULL,
[amount] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aprptvaa] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aprptvaa] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aprptvaa] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aprptvaa] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aprptvaa] TO [public]
GO
