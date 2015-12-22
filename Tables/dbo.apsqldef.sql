CREATE TABLE [dbo].[apsqldef]
(
[sql_id] [int] NOT NULL,
[sql_seq_id] [int] NOT NULL,
[sql_sdesc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sql_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apsqldef_ind_0] ON [dbo].[apsqldef] ([sql_id], [sql_seq_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apsqldef_ind_1] ON [dbo].[apsqldef] ([sql_sdesc], [sql_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apsqldef] TO [public]
GO
GRANT SELECT ON  [dbo].[apsqldef] TO [public]
GO
GRANT INSERT ON  [dbo].[apsqldef] TO [public]
GO
GRANT DELETE ON  [dbo].[apsqldef] TO [public]
GO
GRANT UPDATE ON  [dbo].[apsqldef] TO [public]
GO
