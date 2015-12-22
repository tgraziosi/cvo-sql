CREATE TABLE [dbo].[sched_resource]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL,
[sched_resource_id] [int] NOT NULL IDENTITY(1, 1),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[resource_type_id] [int] NOT NULL,
[resource_id] [int] NULL,
[source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[calendar_id] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schresm2] ON [dbo].[sched_resource] ([sched_id], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schresm1] ON [dbo].[sched_resource] ([sched_id], [source_flag], [resource_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_resource] ON [dbo].[sched_resource] ([sched_resource_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_resource] ADD CONSTRAINT [FK_sched_resource_calendar] FOREIGN KEY ([calendar_id]) REFERENCES [dbo].[calendar] ([calendar_id])
GO
ALTER TABLE [dbo].[sched_resource] WITH NOCHECK ADD CONSTRAINT [FK_sched_resource_sched_location] FOREIGN KEY ([sched_id], [location]) REFERENCES [dbo].[sched_location] ([sched_id], [location]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_resource] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_resource] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_resource] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_resource] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_resource] TO [public]
GO
