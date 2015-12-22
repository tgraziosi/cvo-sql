CREATE TABLE [dbo].[EAI_config]
(
[config_item] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[config_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_config] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_config] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_config] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_config] TO [public]
GO
