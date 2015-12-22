CREATE TABLE [dbo].[tdc_user_config_assign_users]
(
[group_id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_user_config_assign_users] ADD CONSTRAINT [PK_tdc_user_config_assign_users] PRIMARY KEY CLUSTERED  ([group_id], [userid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_user_config_assign_users] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_user_config_assign_users] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_user_config_assign_users] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_user_config_assign_users] TO [public]
GO
