CREATE TABLE [dbo].[cvo_vision_expo_appointments]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[user_login] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isCustomer] [tinyint] NULL CONSTRAINT [DF__cvo_visio__isCus__6CDF18E0] DEFAULT ((0)),
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_from] [datetime] NULL,
[appt_to] [datetime] NULL,
[appt_duration] [smallint] NULL,
[appt_location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[other_location] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_status] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_visio__appt___6DD33D19] DEFAULT ('ACTIVE'),
[created_date] [datetime] NULL CONSTRAINT [DF__cvo_visio__creat__6EC76152] DEFAULT (getdate()),
[modified_date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_appointments] ADD CONSTRAINT [PK__cvo_vision_expo___6BEAF4A7] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
