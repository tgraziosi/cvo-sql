CREATE TABLE [dbo].[user_permissions]
(
[type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[action] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[column_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[user_permissions] TO [public]
GO
GRANT INSERT ON  [dbo].[user_permissions] TO [public]
GO
GRANT DELETE ON  [dbo].[user_permissions] TO [public]
GO
GRANT UPDATE ON  [dbo].[user_permissions] TO [public]
GO
