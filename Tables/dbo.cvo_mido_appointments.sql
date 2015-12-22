CREATE TABLE [dbo].[cvo_mido_appointments]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[user_login] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isCustomer] [tinyint] NULL CONSTRAINT [DF__cvo_mido___isCus__62225EA2] DEFAULT ((0)),
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_from] [datetime] NULL,
[appt_to] [datetime] NULL,
[appt_duration] [smallint] NULL,
[appt_location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[other_location] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_status] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_mido___appt___631682DB] DEFAULT ('ACTIVE'),
[created_date] [datetime] NULL CONSTRAINT [DF__cvo_mido___creat__640AA714] DEFAULT (getdate()),
[modified_date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_mido_appointments] ADD CONSTRAINT [PK__cvo_mido_appoint__612E3A69] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
