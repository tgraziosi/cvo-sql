CREATE TABLE [dbo].[tdc_manifest_carrier_config]
(
[carrier_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[service_type] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_manifest_carrier_config] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_manifest_carrier_config] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_manifest_carrier_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_manifest_carrier_config] TO [public]
GO
