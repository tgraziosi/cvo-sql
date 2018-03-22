CREATE TABLE [dbo].[cvo_crm_leads_info]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[lead_id] [int] NULL,
[run_id] [int] NULL,
[company_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[interest] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[info_date] [datetime] NULL CONSTRAINT [DF__cvo_crm_l__info___44DD119F] DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_info] ADD CONSTRAINT [PK__cvo_crm_leads_in__43E8ED66] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
