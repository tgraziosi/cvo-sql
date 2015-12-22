CREATE TABLE [dbo].[tdc_dist_method]
(
[method] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_dm1_idx] ON [dbo].[tdc_dist_method] ([method]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_method] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_method] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_method] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_method] TO [public]
GO
