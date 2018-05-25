CREATE TABLE [dbo].[cvo_crm_lead_pri]
(
[run_id] [int] NOT NULL IDENTITY(1, 1),
[lead_file] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_source] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[run_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_lead_pri] ADD CONSTRAINT [PK__cvo_crm_lead_pri__5122ECF3] PRIMARY KEY CLUSTERED  ([run_id]) ON [PRIMARY]
GO
