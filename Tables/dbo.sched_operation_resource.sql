CREATE TABLE [dbo].[sched_operation_resource]
(
[timestamp] [timestamp] NOT NULL,
[sched_operation_id] [int] NOT NULL,
[sched_resource_id] [int] NOT NULL,
[setup_datetime] [datetime] NOT NULL,
[pool_qty] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [sched_operation] ON [dbo].[sched_operation_resource] ([sched_operation_id], [sched_resource_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [sched_resource] ON [dbo].[sched_operation_resource] ([sched_resource_id], [sched_operation_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_operation_resource] WITH NOCHECK ADD CONSTRAINT [FK_sched_oper_resource_sched_operation] FOREIGN KEY ([sched_operation_id]) REFERENCES [dbo].[sched_operation] ([sched_operation_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_operation_resource] WITH NOCHECK ADD CONSTRAINT [FK_sched_oper_resource_sched_resource] FOREIGN KEY ([sched_resource_id]) REFERENCES [dbo].[sched_resource] ([sched_resource_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_operation_resource] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_operation_resource] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_operation_resource] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_operation_resource] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_operation_resource] TO [public]
GO
