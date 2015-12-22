CREATE TABLE [dbo].[tdc_user_config_items]
(
[group_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_user_config_items_idx1] ON [dbo].[tdc_user_config_items] ([group_id], [location], [type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_user_config_items] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_user_config_items] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_user_config_items] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_user_config_items] TO [public]
GO
