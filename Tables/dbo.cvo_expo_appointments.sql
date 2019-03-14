CREATE TABLE [dbo].[cvo_expo_appointments]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_login] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[created_by] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_start] [datetime] NULL,
[appt_end] [datetime] NULL,
[appt_duration] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_contact] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_date] [datetime] NULL,
[resched_date] [datetime] NULL,
[cust_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_source] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notify] [tinyint] NULL CONSTRAINT [DF__cvo_expo___notif__5E2FA1F2] DEFAULT ((1)),
[booth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isOutlook] [tinyint] NULL CONSTRAINT [DF__cvo_expo___isOut__5F23C62B] DEFAULT ((0)),
[expo_id] [int] NULL,
[requested_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isNotified] [tinyint] NULL CONSTRAINT [DF__cvo_expo___isNot__1D61BB1D] DEFAULT ((0)),
[cancel_date] [datetime] NULL,
[action_user] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_expo_appointments] ADD CONSTRAINT [PK__cvo_expo_appoint__5D3B7DB9] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
