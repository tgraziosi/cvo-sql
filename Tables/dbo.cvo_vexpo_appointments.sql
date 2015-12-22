CREATE TABLE [dbo].[cvo_vexpo_appointments]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isCustomer] [smallint] NULL CONSTRAINT [DF__cvo_vexpo__isCus__468A8EBC] DEFAULT ('0'),
[account_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_start] [datetime] NULL,
[appt_end] [datetime] NULL,
[appt_title] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_url] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isConf] [smallint] NULL CONSTRAINT [DF__cvo_vexpo__isCon__477EB2F5] DEFAULT ('0'),
[appt_conf] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[schedule_date] [datetime] NULL CONSTRAINT [DF__cvo_vexpo__sched__4872D72E] DEFAULT (getdate()),
[status] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_vexpo__statu__483DCD04] DEFAULT ('ACTIVE'),
[other_location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rep_email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vexpo_appointments] ADD CONSTRAINT [PK__cvo_vexpo_appoin__45966A83] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
