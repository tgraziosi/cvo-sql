CREATE TABLE [dbo].[aprptvoa]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_due] [datetime] NULL,
[date_aging] [datetime] NULL,
[amt_due] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aprptvoa] TO [public]
GO
GRANT SELECT ON  [dbo].[aprptvoa] TO [public]
GO
GRANT INSERT ON  [dbo].[aprptvoa] TO [public]
GO
GRANT DELETE ON  [dbo].[aprptvoa] TO [public]
GO
GRANT UPDATE ON  [dbo].[aprptvoa] TO [public]
GO
