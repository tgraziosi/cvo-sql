CREATE TABLE [dbo].[EAI_Messages]
(
[msg_no] [numeric] (18, 0) NOT NULL,
[language] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EAI_Messages_language] DEFAULT ('English'),
[message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_Messages] ADD CONSTRAINT [EAI_Messages_pk] PRIMARY KEY CLUSTERED  ([msg_no], [language]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_Messages] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_Messages] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_Messages] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_Messages] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_Messages] TO [public]
GO
