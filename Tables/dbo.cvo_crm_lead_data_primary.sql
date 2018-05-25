CREATE TABLE [dbo].[cvo_crm_lead_data_primary]
(
[lead_id] [int] NOT NULL IDENTITY(1, 1),
[run_id] [int] NULL,
[company_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_fname] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_lname] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_lead_data_primary] ADD CONSTRAINT [PK__cvo_crm_lead_dat__530B3565] PRIMARY KEY CLUSTERED  ([lead_id]) ON [PRIMARY]
GO
