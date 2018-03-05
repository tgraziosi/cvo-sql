CREATE TABLE [dbo].[cvo_crm_leads_interest]
(
[int_id] [int] NOT NULL IDENTITY(1, 1),
[int_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_interest] ADD CONSTRAINT [PK__cvo_crm_leads_in__2D6F9C62] PRIMARY KEY CLUSTERED  ([int_id]) ON [PRIMARY]
GO
