CREATE TABLE [dbo].[sched_operation_plan]
(
[timestamp] [timestamp] NOT NULL,
[sched_operation_id] [int] NOT NULL,
[line_no] [int] NULL,
[line_id] [int] NOT NULL,
[cell_id] [int] NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[usage_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__usage__6FAB70F5] DEFAULT ((0.0)),
[ave_pool_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_p__709F952E] DEFAULT ((1.0)),
[ave_flat_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_f__7193B967] DEFAULT ((0.0)),
[ave_unit_qty] [float] NOT NULL CONSTRAINT [DF__sched_ope__ave_u__7287DDA0] DEFAULT ((0.0)),
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eff_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_operation_plan] ADD CONSTRAINT [sched_operation_plan_active_cc1] CHECK (([active]='U' OR [active]='B' OR [active]='A'))
GO
ALTER TABLE [dbo].[sched_operation_plan] ADD CONSTRAINT [sched_operation_plan_status_cc1] CHECK (([status]='M' OR [status]='X' OR [status]='R' OR [status]='C' OR [status]='P'))
GO
CREATE NONCLUSTERED INDEX [sched_operation] ON [dbo].[sched_operation_plan] ([sched_operation_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_operation_plan] WITH NOCHECK ADD CONSTRAINT [FK_sched_operation_plan_sched_operation] FOREIGN KEY ([sched_operation_id]) REFERENCES [dbo].[sched_operation] ([sched_operation_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_operation_plan] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_operation_plan] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_operation_plan] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_operation_plan] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_operation_plan] TO [public]
GO
