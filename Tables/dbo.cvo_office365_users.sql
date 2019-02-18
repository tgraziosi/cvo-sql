CREATE TABLE [dbo].[cvo_office365_users]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_office365_users] ADD CONSTRAINT [PK__cvo_office365_us__7966B3CE] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
