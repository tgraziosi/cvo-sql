CREATE TABLE [dbo].[user_indexlist]
(
[table_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_keys] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_with] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[index_fill] [tinyint] NOT NULL,
[update_action] [tinyint] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[user_indexlist] TO [public]
GO
GRANT INSERT ON  [dbo].[user_indexlist] TO [public]
GO
GRANT DELETE ON  [dbo].[user_indexlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[user_indexlist] TO [public]
GO
