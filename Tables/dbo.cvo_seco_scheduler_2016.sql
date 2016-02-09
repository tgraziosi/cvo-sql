CREATE TABLE [dbo].[cvo_seco_scheduler_2016]
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
[cust_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[booth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_seco_scheduler_2016] ADD CONSTRAINT [PK__cvo_seco_schedul__70CBDE6C] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
