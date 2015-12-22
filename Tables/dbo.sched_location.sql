CREATE TABLE [dbo].[sched_location]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_location] ON [dbo].[sched_location] ([sched_id], [location]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_location] ADD CONSTRAINT [FK_sched_location_locations] FOREIGN KEY ([location]) REFERENCES [dbo].[locations_all] ([location])
GO
ALTER TABLE [dbo].[sched_location] WITH NOCHECK ADD CONSTRAINT [FK_sched_location_sched_model] FOREIGN KEY ([sched_id]) REFERENCES [dbo].[sched_model] ([sched_id]) NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_location] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_location] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_location] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_location] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_location] TO [public]
GO
