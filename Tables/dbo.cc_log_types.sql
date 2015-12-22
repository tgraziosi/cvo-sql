CREATE TABLE [dbo].[cc_log_types]
(
[log_type] [tinyint] NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[short_desc] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cc_log_types_idx] ON [dbo].[cc_log_types] ([log_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_log_types] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_log_types] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_log_types] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_log_types] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_log_types] TO [public]
GO
