CREATE TABLE [dbo].[CVO_order_qty_hist_summary]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[shipped] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CVO_order_qty_hist_summary_ind_0] ON [dbo].[CVO_order_qty_hist_summary] ([location], [part_no], [date_shipped]) ON [PRIMARY]
GO
