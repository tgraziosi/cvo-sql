CREATE TABLE [dbo].[tdc_dist_pick_queue]
(
[seq] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupid] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pack_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_0] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_1] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_2] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_3] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_4] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_5] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_6] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_7] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_8] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_bin_9] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_pick_queue] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_pick_queue] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_pick_queue] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_pick_queue] TO [public]
GO
