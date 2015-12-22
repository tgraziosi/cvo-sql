CREATE TABLE [dbo].[tdc_module_group]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[group_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_desc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_module_group] ADD CONSTRAINT [PK_tdc_module_group_name] PRIMARY KEY NONCLUSTERED  ([group_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_module_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_module_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_module_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_module_group] TO [public]
GO
