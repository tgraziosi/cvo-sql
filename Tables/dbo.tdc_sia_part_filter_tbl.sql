CREATE TABLE [dbo].[tdc_sia_part_filter_tbl]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_sia_part_filter_tbl_indx1] ON [dbo].[tdc_sia_part_filter_tbl] ([userid], [template_code], [location], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_sia_part_filter_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_sia_part_filter_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_sia_part_filter_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_sia_part_filter_tbl] TO [public]
GO
