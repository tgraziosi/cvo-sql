CREATE TABLE [dbo].[txferlist]
(
[timestamp] [timestamp] NOT NULL,
[xfer_no] [int] NOT NULL,
[from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_entered] [datetime] NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[txferlist] TO [public]
GO
GRANT SELECT ON  [dbo].[txferlist] TO [public]
GO
GRANT INSERT ON  [dbo].[txferlist] TO [public]
GO
GRANT DELETE ON  [dbo].[txferlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[txferlist] TO [public]
GO
