CREATE TABLE [dbo].[cvo_portal_new_customer_invites]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_contact] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isRead] [tinyint] NULL CONSTRAINT [DF__cvo_porta__isRea__1A71D687] DEFAULT ((0)),
[isClicked] [tinyint] NULL CONSTRAINT [DF__cvo_porta__isCli__1B65FAC0] DEFAULT ((0)),
[invite_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invite_date] [datetime] NULL CONSTRAINT [DF__cvo_porta__invit__1C5A1EF9] DEFAULT (getdate()),
[isRegistered] [tinyint] NULL CONSTRAINT [DF__cvo_porta__isReg__202AAFDD] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_portal_new_customer_invites] ADD CONSTRAINT [PK__cvo_portal_new_c__197DB24E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
