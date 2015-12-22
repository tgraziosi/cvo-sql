CREATE TABLE [dbo].[colinfo]
(
[timestamp] [timestamp] NOT NULL,
[table_name] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_id] [int] NOT NULL,
[master_column_id] [int] NOT NULL,
[description] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [colinfo_ind_0] ON [dbo].[colinfo] ([column_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [colinfo_ind_2] ON [dbo].[colinfo] ([master_column_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [colinfo_ind_1] ON [dbo].[colinfo] ([table_name], [column_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[colinfo] TO [public]
GO
GRANT SELECT ON  [dbo].[colinfo] TO [public]
GO
GRANT INSERT ON  [dbo].[colinfo] TO [public]
GO
GRANT DELETE ON  [dbo].[colinfo] TO [public]
GO
GRANT UPDATE ON  [dbo].[colinfo] TO [public]
GO
