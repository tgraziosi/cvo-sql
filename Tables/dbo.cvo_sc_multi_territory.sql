CREATE TABLE [dbo].[cvo_sc_multi_territory]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_login] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_address] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_multi_territory] ADD CONSTRAINT [PK__cvo_sc_multi_ter__46862E46] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
