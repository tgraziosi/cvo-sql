CREATE TABLE [dbo].[cvo_ephs_order_tracking]
(
[sales_rep] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_amount] [float] NULL,
[order_date] [datetime] NULL,
[email] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_sync] [datetime] NULL,
[territory] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
