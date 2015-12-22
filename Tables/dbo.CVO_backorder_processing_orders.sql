CREATE TABLE [dbo].[CVO_backorder_processing_orders]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[template_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[display_order] [int] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[order_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[so_priority] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_date] [datetime] NULL,
[customer_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[available] [decimal] (20, 8) NULL,
[po_available] [decimal] (20, 8) NULL,
[allocated] [decimal] (20, 8) NULL,
[stock_allocated] [decimal] (20, 8) NULL,
[po_allocated] [decimal] (20, 8) NULL,
[process] [smallint] NOT NULL,
[processed] [smallint] NOT NULL,
[tran_type_sort] [smallint] NOT NULL,
[order_type_sort] [smallint] NOT NULL,
[priority_sort] [smallint] NOT NULL,
[backorder_sort] [smallint] NOT NULL,
[stock_locked] [smallint] NOT NULL,
[po_locked] [smallint] NOT NULL,
[is_available] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_inx01] ON [dbo].[CVO_backorder_processing_orders] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_inx02] ON [dbo].[CVO_backorder_processing_orders] ([template_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_inx03] ON [dbo].[CVO_backorder_processing_orders] ([template_code], [order_no], [ext], [line_no], [type], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_orders] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_orders] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_orders] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_orders] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_orders] TO [public]
GO
