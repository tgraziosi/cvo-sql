CREATE TABLE [dbo].[cvo_fl_holds_snapshot]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[fill_perc] [decimal] (20, 8) NULL,
[line_no] [int] NULL,
[ordered] [decimal] (20, 8) NULL,
[in_stock] [decimal] (20, 8) NULL,
[in_stock_na] [decimal] (20, 8) NULL,
[quar_qty] [decimal] (20, 8) NULL,
[soft_alloc_qty] [decimal] (20, 8) NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_qty] [decimal] (20, 8) NULL,
[bin_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[non_alloc_flag] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alloc_qty] [decimal] (20, 8) NULL,
[calc_qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_fl_holds_snapshot] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_fl_holds_snapshot] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_fl_holds_snapshot] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_fl_holds_snapshot] TO [public]
GO
