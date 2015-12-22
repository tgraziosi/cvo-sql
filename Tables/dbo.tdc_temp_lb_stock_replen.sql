CREATE TABLE [dbo].[tdc_temp_lb_stock_replen]
(
[sqlid] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_temp_lb_stock_replen] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_temp_lb_stock_replen] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_temp_lb_stock_replen] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_temp_lb_stock_replen] TO [public]
GO
