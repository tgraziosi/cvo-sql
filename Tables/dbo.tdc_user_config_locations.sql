CREATE TABLE [dbo].[tdc_user_config_locations]
(
[group_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_user_location_idx1] ON [dbo].[tdc_user_config_locations] ([group_id], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_user_config_locations] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_user_config_locations] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_user_config_locations] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_user_config_locations] TO [public]
GO
