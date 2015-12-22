CREATE TABLE [dbo].[cvo_lead_runs]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[run_date] [datetime] NULL,
[lead_file] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_login] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_lead_runs] ADD CONSTRAINT [PK__cvo_lead_runs__6B81ABAA] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
