CREATE TABLE [dbo].[tdc_dist_group]
(
[method] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[parent_serial_no] [int] NOT NULL,
[child_serial_no] [int] NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[function] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_dg2_idx] ON [dbo].[tdc_dist_group] ([child_serial_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_tdg1_idx] ON [dbo].[tdc_dist_group] ([parent_serial_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_group] TO [public]
GO
