CREATE TABLE [dbo].[resource_avail]
(
[timestamp] [timestamp] NOT NULL,
[batch_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[avail_date] [datetime] NOT NULL,
[commit_ed] [decimal] (20, 8) NOT NULL,
[source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temp_qty] [decimal] (20, 8) NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL CONSTRAINT [DF__resource___row_i__3D54FB52] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ravail1] ON [dbo].[resource_avail] ([batch_id], [location], [status], [part_no], [source], [source_no], [avail_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ravail2] ON [dbo].[resource_avail] ([row_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_avail] ADD CONSTRAINT [FK_resource_avail_resource_batch_batch_id] FOREIGN KEY ([batch_id]) REFERENCES [dbo].[resource_batch] ([batch_id])
GO
GRANT REFERENCES ON  [dbo].[resource_avail] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_avail] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_avail] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_avail] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_avail] TO [public]
GO
