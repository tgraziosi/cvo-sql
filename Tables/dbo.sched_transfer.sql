CREATE TABLE [dbo].[sched_transfer]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL,
[sched_transfer_id] [int] NOT NULL IDENTITY(1, 1),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[move_datetime] [datetime] NOT NULL,
[source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[xfer_no] [int] NULL,
[xfer_line] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [sched_location] ON [dbo].[sched_transfer] ([sched_id], [location]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_transfer] ON [dbo].[sched_transfer] ([sched_transfer_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_transfer] WITH NOCHECK ADD CONSTRAINT [FK_sched_transfer_sched_location] FOREIGN KEY ([sched_id], [location]) REFERENCES [dbo].[sched_location] ([sched_id], [location]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_transfer] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_transfer] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_transfer] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_transfer] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_transfer] TO [public]
GO
