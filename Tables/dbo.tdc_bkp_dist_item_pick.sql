CREATE TABLE [dbo].[tdc_bkp_dist_item_pick]
(
[method] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[child_serial_no] [int] NOT NULL,
[function] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bkp_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bkp_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [TDC_BKP_ITEM_PICK_INDEX] ON [dbo].[tdc_bkp_dist_item_pick] ([order_no], [order_ext], [line_no], [child_serial_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bkp_dist_item_pick] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bkp_dist_item_pick] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bkp_dist_item_pick] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bkp_dist_item_pick] TO [public]
GO
