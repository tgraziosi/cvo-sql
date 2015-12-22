CREATE TABLE [dbo].[tdc_3pl_assigned_bins]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_assigned_bins_idx2] ON [dbo].[tdc_3pl_assigned_bins] ([bin_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_assigned_bins_idx1] ON [dbo].[tdc_3pl_assigned_bins] ([location], [template_name], [type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_assigned_bins] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_assigned_bins] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_assigned_bins] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_assigned_bins] TO [public]
GO
