CREATE TABLE [dbo].[cvo_lead_trackerdb]
(
[lead_id] [int] NOT NULL IDENTITY(1, 1),
[lead_category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_fname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_lname] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_company] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_account] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_zipcode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_country] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_territory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_submit_date] [datetime] NULL CONSTRAINT [DF__cvo_lead___lead___54E13906] DEFAULT (getdate()),
[isCustomer] [smallint] NULL CONSTRAINT [DF__cvo_lead___isCus__58B1C9EA] DEFAULT ((0)),
[isAddressMatch] [smallint] NULL CONSTRAINT [DF__cvo_lead___isAdd__59A5EE23] DEFAULT ((0)),
[lead_status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_lead___lead___343F5F4A] DEFAULT ('New'),
[lead_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_lead_trackerdb] ADD CONSTRAINT [PK__cvo_lead_tracker__6ED61533] PRIMARY KEY CLUSTERED  ([lead_id]) ON [PRIMARY]
GO
