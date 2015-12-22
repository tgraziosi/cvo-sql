CREATE TABLE [dbo].[cvo_appt_orders]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[activity] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[app_id] [int] NULL,
[region] [int] NULL,
[territory] [int] NULL,
[isNew] [tinyint] NULL,
[isReactive] [tinyint] NULL,
[customer] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_start] [datetime] NULL,
[appt_end] [datetime] NULL,
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order_value] [float] NULL,
[load_date] [datetime] NULL CONSTRAINT [DF__cvo_appt___load___3425BE71] DEFAULT (getdate()),
[hs_order_date] [datetime] NULL,
[sync_date] [datetime] NULL,
[hs_order_status] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ep_order_no] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ep_order_status] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_appt_orders] ADD CONSTRAINT [PK__cvo_appt_orders__33319A38] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
