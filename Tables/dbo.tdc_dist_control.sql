CREATE TABLE [dbo].[tdc_dist_control]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[control_ind] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_control] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_control] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_control] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_control] TO [public]
GO
