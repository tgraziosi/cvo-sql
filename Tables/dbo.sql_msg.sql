CREATE TABLE [dbo].[sql_msg]
(
[timestamp] [timestamp] NOT NULL,
[code] [int] NOT NULL,
[severity] [int] NULL,
[dlevel] [int] NULL,
[msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[language] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sql_msg_ndx] ON [dbo].[sql_msg] ([code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sql_msg] TO [public]
GO
GRANT SELECT ON  [dbo].[sql_msg] TO [public]
GO
GRANT INSERT ON  [dbo].[sql_msg] TO [public]
GO
GRANT DELETE ON  [dbo].[sql_msg] TO [public]
GO
GRANT UPDATE ON  [dbo].[sql_msg] TO [public]
GO
