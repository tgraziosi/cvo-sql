CREATE TABLE [dbo].[tdc_graphical_bin_view_bin_type_color_tbl]
(
[template_viewbyid] [int] NOT NULL,
[open_color] [int] NOT NULL,
[prodin_color] [int] NOT NULL,
[prodout_color] [int] NOT NULL,
[quarantine_color] [int] NOT NULL,
[receipt_color] [int] NOT NULL,
[replenish_color] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_graphical_bin_view_bin_type_color_tbl_idx1] ON [dbo].[tdc_graphical_bin_view_bin_type_color_tbl] ([template_viewbyid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_graphical_bin_view_bin_type_color_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_graphical_bin_view_bin_type_color_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_graphical_bin_view_bin_type_color_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_graphical_bin_view_bin_type_color_tbl] TO [public]
GO
