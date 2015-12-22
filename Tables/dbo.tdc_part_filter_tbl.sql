CREATE TABLE [dbo].[tdc_part_filter_tbl]
(
[alloc_filter] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_part_filter_tbl_indx1] ON [dbo].[tdc_part_filter_tbl] ([alloc_filter], [location], [order_type], [part_type], [userid], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_part_filter_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_part_filter_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_part_filter_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_part_filter_tbl] TO [public]
GO
