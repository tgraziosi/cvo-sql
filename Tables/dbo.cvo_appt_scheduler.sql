CREATE TABLE [dbo].[cvo_appt_scheduler]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_start] [datetime] NULL,
[appt_end] [datetime] NULL,
[isCustomer] [smallint] NULL CONSTRAINT [DF__cvo_appt___isCus__000499E8] DEFAULT ('0'),
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_contact] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isValid] [smallint] NULL CONSTRAINT [DF__cvo_appt___isVal__00F8BE21] DEFAULT ('0'),
[status] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_appt___statu__05BD733E] DEFAULT ('ACTIVE'),
[user_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isReactive] [smallint] NULL CONSTRAINT [DF__cvo_appt___isRea__7369B8D9] DEFAULT ((0)),
[new_address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_state] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_zip] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_appt___new_c__76462584] DEFAULT ('US'),
[isNew] [smallint] NULL CONSTRAINT [DF__cvo_appt___isNew__773A49BD] DEFAULT ('0'),
[mapped_account] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_duration] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order_no] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prev_st_order_date] [datetime] NULL,
[isValidAccount] [smallint] NULL CONSTRAINT [DF__cvo_appt___isVal__3E76CDAD] DEFAULT ('1'),
[sched_date] [datetime] NULL,
[resched_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_appt_scheduler] ADD CONSTRAINT [PK__cvo_appt_schedul__7F1075AF] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
