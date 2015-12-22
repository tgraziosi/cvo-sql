CREATE TABLE [dbo].[sql_log]
(
[timestamp] [timestamp] NOT NULL,
[log_date] [datetime] NULL,
[log_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sql_log] TO [public]
GO
GRANT SELECT ON  [dbo].[sql_log] TO [public]
GO
GRANT INSERT ON  [dbo].[sql_log] TO [public]
GO
GRANT DELETE ON  [dbo].[sql_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[sql_log] TO [public]
GO
