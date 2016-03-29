CREATE TABLE [dbo].[cvo_eyerep_acthis_tbl]
(
[account_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDER_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_amt] [decimal] (9, 2) NOT NULL,
[ship_amt] [decimal] (9, 2) NOT NULL,
[WebOrderNumber] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Invoice_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [decimal] (9, 2) NOT NULL,
[price] [decimal] (9, 2) NOT NULL,
[ship_date] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDER_status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
