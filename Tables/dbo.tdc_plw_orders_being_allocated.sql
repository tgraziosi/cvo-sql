CREATE TABLE [dbo].[tdc_plw_orders_being_allocated]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[username] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_plw_orders_being_allocated_idx1] ON [dbo].[tdc_plw_orders_being_allocated] ([order_no], [order_ext], [order_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_plw_orders_being_allocated_idx2] ON [dbo].[tdc_plw_orders_being_allocated] ([username]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_plw_orders_being_allocated] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_plw_orders_being_allocated] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_plw_orders_being_allocated] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_plw_orders_being_allocated] TO [public]
GO
