CREATE TABLE [dbo].[cvo_cart_orders_processed]
(
[order_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[processed_date] [datetime] NULL,
[scan_date] [datetime] NULL,
[pickComplete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cart___pickC__4E75FB11] DEFAULT ('N'),
[scan_user] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_set] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [PR_ORDERS] ON [dbo].[cvo_cart_orders_processed] ([order_no], [scan_user], [scan_date], [cart_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cart_orders_proc_idx1] ON [dbo].[cvo_cart_orders_processed] ([order_status], [processed_date], [order_no]) ON [PRIMARY]
GO
