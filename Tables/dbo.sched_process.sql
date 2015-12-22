CREATE TABLE [dbo].[sched_process]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL,
[sched_process_id] [int] NOT NULL IDENTITY(1, 1),
[process_unit] [float] NOT NULL,
[process_unit_orig] [float] NOT NULL,
[source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[status_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_order_id] [int] NULL,
[qc_no] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schprocm2] ON [dbo].[sched_process] ([sched_id], [sched_process_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schprocm1] ON [dbo].[sched_process] ([sched_id], [source_flag], [prod_no], [prod_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schprocm3] ON [dbo].[sched_process] ([sched_id], [source_flag], [sched_process_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_process] ON [dbo].[sched_process] ([sched_process_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_process] ADD CONSTRAINT [FK_sched_process_produce] FOREIGN KEY ([prod_no], [prod_ext]) REFERENCES [dbo].[produce_all] ([prod_no], [prod_ext])
GO
ALTER TABLE [dbo].[sched_process] WITH NOCHECK ADD CONSTRAINT [FK_sched_process_sched_model] FOREIGN KEY ([sched_id]) REFERENCES [dbo].[sched_model] ([sched_id]) NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_process] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_process] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_process] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_process] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_process] TO [public]
GO
