CREATE TABLE [dbo].[cvo_crm_lead_data_secondary]
(
[sec_id] [int] NOT NULL IDENTITY(1, 1),
[lead_id] [int] NULL,
[run_id] [int] NULL,
[sec_company_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_contact_fname] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_contact_lname] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_fax] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_zip_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sec_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_lead_data_secondary] ADD CONSTRAINT [PK__cvo_crm_lead_dat__54F37DD7] PRIMARY KEY CLUSTERED  ([sec_id]) ON [PRIMARY]
GO
