CREATE TABLE [dbo].[cvo_appointment_scheduler]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[user_login] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isCustomer] [tinyint] NULL CONSTRAINT [DF__cvo_appoi__isCus__197F1732] DEFAULT ((0)),
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_from] [datetime] NULL,
[appt_to] [datetime] NULL,
[appt_duration] [smallint] NULL,
[appt_location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[other_location] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_status] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_appoi__appt___1A733B6B] DEFAULT ('ACTIVE'),
[created_date] [datetime] NULL CONSTRAINT [DF__cvo_appoi__creat__1B675FA4] DEFAULT (getdate()),
[modified_date] [datetime] NULL,
[cust_type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_source] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_status] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_appointment_scheduler] ADD CONSTRAINT [PK__cvo_appointment___188AF2F9] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
