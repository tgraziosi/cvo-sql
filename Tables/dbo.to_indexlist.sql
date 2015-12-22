CREATE TABLE [dbo].[to_indexlist]
(
[table_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_keys] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_desc] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_with] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_fill] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[to_indexlist] TO [public]
GO
GRANT INSERT ON  [dbo].[to_indexlist] TO [public]
GO
GRANT DELETE ON  [dbo].[to_indexlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[to_indexlist] TO [public]
GO
