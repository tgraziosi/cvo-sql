CREATE TABLE [dbo].[esc_territory]
(
[CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NAME] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[esc_territory] TO [public]
GO
GRANT INSERT ON  [dbo].[esc_territory] TO [public]
GO
GRANT DELETE ON  [dbo].[esc_territory] TO [public]
GO
GRANT UPDATE ON  [dbo].[esc_territory] TO [public]
GO
