CREATE TABLE [dbo].[tdc_package_part]
(
[pkg_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pack_qty] [decimal] (24, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [pkg_master_unique_idx] ON [dbo].[tdc_package_part] ([pkg_code], [location], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_package_part] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_package_part] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_package_part] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_package_part] TO [public]
GO
