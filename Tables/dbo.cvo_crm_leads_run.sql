CREATE TABLE [dbo].[cvo_crm_leads_run]
(
[run_id] [int] NOT NULL IDENTITY(1, 1),
[lead_file] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_file_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_source] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[run_date] [datetime] NULL CONSTRAINT [DF__cvo_crm_l__run_d__3B53A765] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_run] ADD CONSTRAINT [PK__cvo_crm_leads_ru__3A5F832C] PRIMARY KEY CLUSTERED  ([run_id]) ON [PRIMARY]
GO
