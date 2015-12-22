CREATE TABLE [dbo].[tdc_module_functions]
(
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Source] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Function] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_tdc_module_functions] ON [dbo].[tdc_module_functions] ([module], [Source], [Function]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_module_functions] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_module_functions] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_module_functions] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_module_functions] TO [public]
GO
