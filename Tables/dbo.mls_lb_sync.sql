CREATE TABLE [dbo].[mls_lb_sync]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lbqty] [decimal] (20, 8) NULL,
[begin_stock] [decimal] (20, 8) NULL,
[in_stock] [decimal] (20, 8) NULL,
[rec_sum] [decimal] (20, 8) NULL,
[ship_sum] [decimal] (20, 8) NULL,
[sales_sum] [decimal] (20, 8) NULL,
[xfer_to] [decimal] (20, 8) NULL,
[xfer_from] [decimal] (20, 8) NULL,
[iss_sum] [decimal] (20, 8) NULL,
[mfg_sum] [decimal] (20, 8) NULL,
[used_sum] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [mls1] ON [dbo].[mls_lb_sync] ([location], [part_no]) ON [PRIMARY]
GO
