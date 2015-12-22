CREATE TABLE [dbo].[cvo_vew_order_history]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_order_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ep_order_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_date] [datetime] NULL,
[order_date] [datetime] NULL,
[order_pcs] [int] NULL,
[order_value] [float] NULL,
[territory_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vew_order_history] ADD CONSTRAINT [PK__cvo_vew_order_hi__1A608ED7] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
