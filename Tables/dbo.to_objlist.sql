CREATE TABLE [dbo].[to_objlist]
(
[table_name] [char] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [char] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[data_type] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[data_length] [smallint] NOT NULL,
[colid] [smallint] NOT NULL,
[status] [smallint] NOT NULL,
[prec] [smallint] NULL,
[scale] [smallint] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[to_objlist] TO [public]
GO
GRANT INSERT ON  [dbo].[to_objlist] TO [public]
GO
GRANT DELETE ON  [dbo].[to_objlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[to_objlist] TO [public]
GO
