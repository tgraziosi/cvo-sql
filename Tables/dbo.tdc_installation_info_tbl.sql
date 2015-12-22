CREATE TABLE [dbo].[tdc_installation_info_tbl]
(
[product] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[product_version] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[file_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[object_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_installed] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_installed] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_installation_info_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_installation_info_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_installation_info_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_installation_info_tbl] TO [public]
GO
