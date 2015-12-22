CREATE TABLE [dbo].[tdc_bk_orders]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[ord_qty] [decimal] (20, 8) NOT NULL,
[bk_qty] [decimal] (20, 8) NOT NULL,
[user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tx_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bk_orders] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bk_orders] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bk_orders] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bk_orders] TO [public]
GO
