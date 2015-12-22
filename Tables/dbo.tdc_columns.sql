CREATE TABLE [dbo].[tdc_columns]
(
[table_view_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[col_id] [tinyint] NULL,
[column_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[column_length] [int] NULL,
[show_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[allow_nulls] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_columns] ADD CONSTRAINT [PK_tdc_columns] PRIMARY KEY NONCLUSTERED  ([table_view_name], [column_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_columns] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_columns] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_columns] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_columns] TO [public]
GO
