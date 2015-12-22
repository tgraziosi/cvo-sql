CREATE TABLE [dbo].[CVO_backorder_processing_orders_ringfenced_stock]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_reqd] [decimal] (20, 8) NOT NULL,
[qty_ringfenced] [decimal] (20, 8) NOT NULL,
[qty_processed] [decimal] (20, 8) NOT NULL,
[status] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_backorder_processing_orders_ringfenced_stock_pk] ON [dbo].[CVO_backorder_processing_orders_ringfenced_stock] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_ringfenced_stock_inx03] ON [dbo].[CVO_backorder_processing_orders_ringfenced_stock] ([status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_ringfenced_stock_inx01] ON [dbo].[CVO_backorder_processing_orders_ringfenced_stock] ([template_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_ringfenced_stock_inx02] ON [dbo].[CVO_backorder_processing_orders_ringfenced_stock] ([template_code], [order_no], [ext], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_orders_ringfenced_stock] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_orders_ringfenced_stock] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_orders_ringfenced_stock] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_orders_ringfenced_stock] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_orders_ringfenced_stock] TO [public]
GO
