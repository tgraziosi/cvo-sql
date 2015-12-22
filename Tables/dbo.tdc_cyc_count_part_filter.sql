CREATE TABLE [dbo].[tdc_cyc_count_part_filter]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_cyc_count_part_filter_indx1] ON [dbo].[tdc_cyc_count_part_filter] ([userid], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cyc_count_part_filter] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cyc_count_part_filter] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cyc_count_part_filter] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cyc_count_part_filter] TO [public]
GO
