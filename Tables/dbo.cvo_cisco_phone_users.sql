CREATE TABLE [dbo].[cvo_cisco_phone_users]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_name] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ext] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cisco_phone_users] ADD CONSTRAINT [PK__cvo_cisco_phone___44B22916] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
