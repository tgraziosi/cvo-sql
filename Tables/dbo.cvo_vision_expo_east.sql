CREATE TABLE [dbo].[cvo_vision_expo_east]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_start] [datetime] NULL,
[appt_end] [datetime] NULL,
[appt_duration] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order_no] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_contact] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_date] [datetime] NULL,
[resched_date] [datetime] NULL,
[cust_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_source] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notify] [tinyint] NULL CONSTRAINT [DF__cvo_visio__notif__5F62269F] DEFAULT ((1)),
[booth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_code] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isOutlook] [tinyint] NULL CONSTRAINT [DF__cvo_visio__isOut__0BCAB8C2] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_east] ADD CONSTRAINT [PK__cvo_vision_expo___60564AD8] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
