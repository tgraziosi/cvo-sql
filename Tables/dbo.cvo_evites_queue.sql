CREATE TABLE [dbo].[cvo_evites_queue]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[evite_date] [datetime] NULL CONSTRAINT [DF__cvo_evite__evite__0D82BB14] DEFAULT (getdate()),
[territory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_login] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[program] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[request_group] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_evites_queue] ADD CONSTRAINT [PK__cvo_evites_queue__0C8E96DB] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
