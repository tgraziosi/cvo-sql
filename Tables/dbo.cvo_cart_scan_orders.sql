CREATE TABLE [dbo].[cvo_cart_scan_orders]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scan_date] [datetime] NULL,
[scan_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sno] [int] NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cart_scan_orders] ADD CONSTRAINT [PK__cvo_cart_scan_or__096A41A8] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cartorders] ON [dbo].[cvo_cart_scan_orders] ([order_no], [scan_user]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CT_ORD] ON [dbo].[cvo_cart_scan_orders] ([order_no], [scan_user]) ON [PRIMARY]
GO
