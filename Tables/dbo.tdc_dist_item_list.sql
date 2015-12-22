CREATE TABLE [dbo].[tdc_dist_item_list]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[function] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_dist_item_list_idx1] ON [dbo].[tdc_dist_item_list] ([order_no], [order_ext], [function], [line_no], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_item_list] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_item_list] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_item_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_item_list] TO [public]
GO
