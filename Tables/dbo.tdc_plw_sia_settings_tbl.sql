CREATE TABLE [dbo].[tdc_plw_sia_settings_tbl]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[criteria_template] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_template] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_plw_sia_settings_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_plw_sia_settings_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_plw_sia_settings_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_plw_sia_settings_tbl] TO [public]
GO
