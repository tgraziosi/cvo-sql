CREATE TABLE [dbo].[tdc_package_usage_type]
(
[usage_type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_package_usage_type] ADD CONSTRAINT [PK_tdc_package_usage_type1__15] PRIMARY KEY CLUSTERED  ([usage_type_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_package_usage_type] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_package_usage_type] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_package_usage_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_package_usage_type] TO [public]
GO
