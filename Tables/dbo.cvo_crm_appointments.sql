CREATE TABLE [dbo].[cvo_crm_appointments]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[user_login] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isCustomer] [tinyint] NULL CONSTRAINT [DF__cvo_crm_a__isCus__3262359A] DEFAULT ((0)),
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_from] [datetime] NULL,
[appt_to] [datetime] NULL,
[appt_duration] [smallint] NULL,
[appt_location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[other_location] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_status] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_crm_a__appt___335659D3] DEFAULT ('ACTIVE'),
[created_date] [datetime] NULL CONSTRAINT [DF__cvo_crm_a__creat__344A7E0C] DEFAULT (getdate()),
[modified_date] [datetime] NULL,
[lead_id] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_appointments] ADD CONSTRAINT [PK__cvo_crm_appointm__316E1161] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
