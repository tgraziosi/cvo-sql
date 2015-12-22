CREATE TABLE [dbo].[sched_operation]
(
[timestamp] [timestamp] NOT NULL,
[sched_operation_id] [int] NOT NULL IDENTITY(1, 1),
[sched_process_id] [int] NOT NULL,
[operation_step] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ave_flat_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_f__63459A10] DEFAULT ((0.0)),
[ave_unit_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_u__6439BE49] DEFAULT ((0.0)),
[ave_wait_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_w__652DE282] DEFAULT ((0.0)),
[ave_flat_time] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_f__662206BB] DEFAULT ((0.0)),
[ave_unit_time] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_u__67162AF4] DEFAULT ((0.0)),
[operation_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_ope__opera__680A4F2D] DEFAULT ('M'),
[complete_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__compl__68FE7366] DEFAULT ((0.0)),
[discard_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__disca__69F2979F] DEFAULT ((0.0)),
[operation_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_ope__opera__6AE6BBD8] DEFAULT ('U'),
[work_datetime] [datetime] NULL,
[done_datetime] [datetime] NULL,
[scheduled_duration] [float] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_operation] ON [dbo].[sched_operation] ([sched_operation_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [sched_process] ON [dbo].[sched_operation] ([sched_process_id], [operation_step]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_operation] WITH NOCHECK ADD CONSTRAINT [FK_sched_operation_locations] FOREIGN KEY ([location]) REFERENCES [dbo].[locations_all] ([location]) NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_operation] WITH NOCHECK ADD CONSTRAINT [FK_sched_operation_sched_process] FOREIGN KEY ([sched_process_id]) REFERENCES [dbo].[sched_process] ([sched_process_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_operation] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_operation] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_operation] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_operation] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_operation] TO [public]
GO
