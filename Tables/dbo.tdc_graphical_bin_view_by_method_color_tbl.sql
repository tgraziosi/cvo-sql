CREATE TABLE [dbo].[tdc_graphical_bin_view_by_method_color_tbl]
(
[template_viewbyid] [int] NOT NULL,
[seq_no] [int] NOT NULL,
[bin_section] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_color] [int] NOT NULL,
[bin_caption] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_tooltip] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_graphical_bin_view_by_method_color_tbl_idx1] ON [dbo].[tdc_graphical_bin_view_by_method_color_tbl] ([template_viewbyid], [seq_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_graphical_bin_view_by_method_color_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_graphical_bin_view_by_method_color_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_graphical_bin_view_by_method_color_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_graphical_bin_view_by_method_color_tbl] TO [public]
GO
