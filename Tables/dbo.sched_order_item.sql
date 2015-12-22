CREATE TABLE [dbo].[sched_order_item]
(
[timestamp] [timestamp] NOT NULL,
[sched_order_id] [int] NOT NULL,
[sched_item_id] [int] NOT NULL,
[uom_qty] [float] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[demand_datetime] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schorditm1] ON [dbo].[sched_order_item] ([sched_item_id], [sched_order_id], [uom_qty]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schorditm2] ON [dbo].[sched_order_item] ([sched_order_id], [sched_item_id], [uom_qty]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_order_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_order_item_sched_item] FOREIGN KEY ([sched_item_id]) REFERENCES [dbo].[sched_item] ([sched_item_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_order_item] WITH NOCHECK ADD CONSTRAINT [FK_sched_order_item_sched_order] FOREIGN KEY ([sched_order_id]) REFERENCES [dbo].[sched_order] ([sched_order_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_order_item] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_order_item] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_order_item] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_order_item] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_order_item] TO [public]
GO
