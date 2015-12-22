CREATE TABLE [dbo].[tdc_user_config_assign_groups]
(
[group_id] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (275) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[override_q_priority] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_user___overr__06A24E38] DEFAULT ('N'),
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_user___exper__07967271] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_user_config_assign_groups] ADD CONSTRAINT [PK_tdc_user_config_assign_groups] PRIMARY KEY CLUSTERED  ([group_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_user_config_assign_groups] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_user_config_assign_groups] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_user_config_assign_groups] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_user_config_assign_groups] TO [public]
GO
