CREATE TABLE [dbo].[arcusmerobjects]
(
[sequence_id] [int] NOT NULL,
[object_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[table_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[procedure_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipto_column] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipto_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcusmerobjects_o] ON [dbo].[arcusmerobjects] ([object_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcusmerobjects] TO [public]
GO
GRANT SELECT ON  [dbo].[arcusmerobjects] TO [public]
GO
GRANT INSERT ON  [dbo].[arcusmerobjects] TO [public]
GO
GRANT DELETE ON  [dbo].[arcusmerobjects] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcusmerobjects] TO [public]
GO
