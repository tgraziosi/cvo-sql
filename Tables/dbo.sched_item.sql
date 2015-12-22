CREATE TABLE [dbo].[sched_item]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL,
[sched_item_id] [int] NOT NULL IDENTITY(1, 1),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[done_datetime] [datetime] NOT NULL,
[uom_qty] [float] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sched_process_id] [int] NULL,
[sched_transfer_id] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schitemm6] ON [dbo].[sched_item] ([sched_id], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schitemm1] ON [dbo].[sched_item] ([sched_id], [location], [part_no], [source_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schitemm3] ON [dbo].[sched_item] ([sched_id], [sched_transfer_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schitemm2] ON [dbo].[sched_item] ([sched_id], [source_flag], [sched_item_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [source] ON [dbo].[sched_item] ([sched_id], [source_flag], [sched_process_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_item] ON [dbo].[sched_item] ([sched_item_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schitemm4] ON [dbo].[sched_item] ([sched_process_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schitemm5] ON [dbo].[sched_item] ([sched_transfer_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_item_sched_location] FOREIGN KEY ([sched_id], [location]) REFERENCES [dbo].[sched_location] ([sched_id], [location]) NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_item_sched_process] FOREIGN KEY ([sched_process_id]) REFERENCES [dbo].[sched_process] ([sched_process_id]) NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_item_sched_transfer] FOREIGN KEY ([sched_transfer_id]) REFERENCES [dbo].[sched_transfer] ([sched_transfer_id]) NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_item] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_item] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_item] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_item] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_item] TO [public]
GO
