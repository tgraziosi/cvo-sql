CREATE TABLE [dbo].[sched_transfer_item]
(
[timestamp] [timestamp] NOT NULL,
[sched_transfer_id] [int] NOT NULL,
[sched_item_id] [int] NOT NULL,
[uom_qty] [float] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [sched_item] ON [dbo].[sched_transfer_item] ([sched_item_id], [sched_transfer_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [sched_transfer] ON [dbo].[sched_transfer_item] ([sched_transfer_id], [sched_item_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_transfer_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_transfer_item_sched_item] FOREIGN KEY ([sched_item_id]) REFERENCES [dbo].[sched_item] ([sched_item_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_transfer_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_transfer_item_sched_transfer] FOREIGN KEY ([sched_transfer_id]) REFERENCES [dbo].[sched_transfer] ([sched_transfer_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_transfer_item] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_transfer_item] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_transfer_item] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_transfer_item] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_transfer_item] TO [public]
GO
