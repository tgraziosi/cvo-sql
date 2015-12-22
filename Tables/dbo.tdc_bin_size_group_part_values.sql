CREATE TABLE [dbo].[tdc_bin_size_group_part_values]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_size_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_size_group_part_values_idx1] ON [dbo].[tdc_bin_size_group_part_values] ([part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_size_group_part_values] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_size_group_part_values] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_size_group_part_values] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_size_group_part_values] TO [public]
GO
