CREATE TABLE [dbo].[tdc_dist_modules]
(
[module_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_dmod1_idx] ON [dbo].[tdc_dist_modules] ([module_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_modules] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_modules] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_modules] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_modules] TO [public]
GO
