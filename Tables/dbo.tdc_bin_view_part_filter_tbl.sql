CREATE TABLE [dbo].[tdc_bin_view_part_filter_tbl]
(
[template_id] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_view_part_filter_tbl_idx] ON [dbo].[tdc_bin_view_part_filter_tbl] ([template_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_view_part_filter_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_view_part_filter_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_view_part_filter_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_view_part_filter_tbl] TO [public]
GO
