CREATE TABLE [dbo].[glsqldef]
(
[sql_id] [int] NOT NULL,
[sql_seq_id] [int] NOT NULL,
[sql_sdesc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sql_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glsqldef_ind_0] ON [dbo].[glsqldef] ([sql_id], [sql_seq_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [glsqldef_ind_1] ON [dbo].[glsqldef] ([sql_sdesc], [sql_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glsqldef] TO [public]
GO
GRANT SELECT ON  [dbo].[glsqldef] TO [public]
GO
GRANT INSERT ON  [dbo].[glsqldef] TO [public]
GO
GRANT DELETE ON  [dbo].[glsqldef] TO [public]
GO
GRANT UPDATE ON  [dbo].[glsqldef] TO [public]
GO
