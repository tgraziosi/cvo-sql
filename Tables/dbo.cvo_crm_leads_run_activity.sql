CREATE TABLE [dbo].[cvo_crm_leads_run_activity]
(
[activity_id] [int] NOT NULL IDENTITY(1, 1),
[run_id] [int] NULL,
[lead_id] [int] NULL,
[activity_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_date] [datetime] NULL CONSTRAINT [DF__cvo_crm_l__activ__25CE7A9A] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_run_activity] ADD CONSTRAINT [PK__cvo_crm_leads_ru__24DA5661] PRIMARY KEY CLUSTERED  ([activity_id]) ON [PRIMARY]
GO
