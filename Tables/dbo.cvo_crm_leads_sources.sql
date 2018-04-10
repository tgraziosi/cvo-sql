CREATE TABLE [dbo].[cvo_crm_leads_sources]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[source_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_sources] ADD CONSTRAINT [PK__cvo_crm_leads_so__10F35945] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
