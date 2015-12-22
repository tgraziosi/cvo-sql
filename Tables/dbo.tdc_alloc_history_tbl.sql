CREATE TABLE [dbo].[tdc_alloc_history_tbl]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fill_pct] [decimal] (20, 2) NOT NULL,
[alloc_date] [datetime] NOT NULL,
[alloc_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_alloc_history_tbl_indx1] ON [dbo].[tdc_alloc_history_tbl] ([order_no], [order_ext], [order_type], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_alloc_history_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_alloc_history_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_alloc_history_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_alloc_history_tbl] TO [public]
GO
