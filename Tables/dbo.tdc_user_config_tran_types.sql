CREATE TABLE [dbo].[tdc_user_config_tran_types]
(
[group_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority] [int] NOT NULL,
[times] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_user_config_tran_types_idx01] ON [dbo].[tdc_user_config_tran_types] ([group_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_user_config_tran_types] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_user_config_tran_types] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_user_config_tran_types] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_user_config_tran_types] TO [public]
GO
