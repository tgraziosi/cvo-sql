CREATE TABLE [dbo].[cvo_crm_lead_programs]
(
[prog_id] [int] NOT NULL IDENTITY(1, 1),
[prog_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_lead_programs] ADD CONSTRAINT [PK__cvo_crm_lead_pro__5D88C3D8] PRIMARY KEY CLUSTERED  ([prog_id]) ON [PRIMARY]
GO
