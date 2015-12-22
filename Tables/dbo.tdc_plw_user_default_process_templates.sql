CREATE TABLE [dbo].[tdc_plw_user_default_process_templates]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_plw_user_default_process_templates] ADD CONSTRAINT [PK_tdc_plw_user_default_process_templates] PRIMARY KEY NONCLUSTERED  ([userid], [location], [order_type], [type], [template_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_plw_user_default_process_templates_ind1] ON [dbo].[tdc_plw_user_default_process_templates] ([template_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_plw_user_default_process_templates_ind2] ON [dbo].[tdc_plw_user_default_process_templates] ([userid], [location], [type], [order_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_plw_user_default_process_templates] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_plw_user_default_process_templates] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_plw_user_default_process_templates] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_plw_user_default_process_templates] TO [public]
GO
