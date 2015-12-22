CREATE TABLE [dbo].[cvo_cart_orders_processed]
(
[order_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[processed_date] [datetime] NULL,
[scan_date] [datetime] NULL,
[pickComplete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cart___pickC__4E75FB11] DEFAULT ('N')
) ON [PRIMARY]
GO
