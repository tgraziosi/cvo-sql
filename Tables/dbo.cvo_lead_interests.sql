CREATE TABLE [dbo].[cvo_lead_interests]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[interest] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_lead_interests] ADD CONSTRAINT [PK__cvo_lead_interes__2F4CF7DC] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
