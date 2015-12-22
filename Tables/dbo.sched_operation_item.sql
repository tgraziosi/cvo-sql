CREATE TABLE [dbo].[sched_operation_item]
(
[timestamp] [timestamp] NOT NULL,
[sched_operation_id] [int] NOT NULL,
[sched_item_id] [int] NOT NULL,
[uom_qty] [float] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[demand_datetime] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [sched_item] ON [dbo].[sched_operation_item] ([sched_item_id], [sched_operation_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [sched_operation] ON [dbo].[sched_operation_item] ([sched_operation_id], [sched_item_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_operation_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_operation_item_sched_item] FOREIGN KEY ([sched_item_id]) REFERENCES [dbo].[sched_item] ([sched_item_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_operation_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_operation_item_sched_operation] FOREIGN KEY ([sched_operation_id]) REFERENCES [dbo].[sched_operation] ([sched_operation_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_operation_item] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_operation_item] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_operation_item] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_operation_item] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_operation_item] TO [public]
GO
