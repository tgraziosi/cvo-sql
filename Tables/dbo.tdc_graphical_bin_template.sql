CREATE TABLE [dbo].[tdc_graphical_bin_template]
(
[template_id] [int] NOT NULL IDENTITY(1, 1),
[template_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[view_by_index] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_width] [int] NOT NULL,
[bin_height] [int] NOT NULL,
[vert_spacing] [int] NOT NULL,
[horz_spacing] [int] NOT NULL,
[show_empty_bins] [int] NULL,
[show_captions] [int] NULL,
[empty_bin_caption] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_filter_id] [int] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_graphical_bin_template_idx1] ON [dbo].[tdc_graphical_bin_template] ([template_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_graphical_bin_template_idx2] ON [dbo].[tdc_graphical_bin_template] ([template_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_graphical_bin_template] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_graphical_bin_template] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_graphical_bin_template] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_graphical_bin_template] TO [public]
GO
