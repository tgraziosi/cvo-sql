CREATE TABLE [dbo].[tdc_cyc_count_bin_filter]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_cyc_count_bin_filter_indx1] ON [dbo].[tdc_cyc_count_bin_filter] ([userid], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cyc_count_bin_filter] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cyc_count_bin_filter] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cyc_count_bin_filter] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cyc_count_bin_filter] TO [public]
GO
