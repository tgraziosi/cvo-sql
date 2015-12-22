CREATE TABLE [dbo].[tdc_plw_alloc_template_part_filter]
(
[template_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_plw_alloc_template_part_filter_indx1] ON [dbo].[tdc_plw_alloc_template_part_filter] ([userid], [location], [order_type], [template_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_plw_alloc_template_part_filter] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_plw_alloc_template_part_filter] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_plw_alloc_template_part_filter] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_plw_alloc_template_part_filter] TO [public]
GO
