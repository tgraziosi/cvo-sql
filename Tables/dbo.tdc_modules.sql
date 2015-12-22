CREATE TABLE [dbo].[tdc_modules]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_group] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_modules] ADD CONSTRAINT [PK_tdc_modules_module] PRIMARY KEY NONCLUSTERED  ([module]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_modules] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_modules] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_modules] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_modules] TO [public]
GO
