CREATE TABLE [dbo].[sched_process_product]
(
[timestamp] [timestamp] NOT NULL,
[sched_process_product_id] [int] NOT NULL IDENTITY(1, 1),
[sched_process_id] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[uom_qty] [float] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[usage_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_pct] [float] NOT NULL CONSTRAINT [DF__sched_pro__cost___7DF9904C] DEFAULT ((100.0)),
[bom_rev] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [sched_process] ON [dbo].[sched_process_product] ([sched_process_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [sched_process_product] ON [dbo].[sched_process_product] ([sched_process_product_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_process_product] WITH NOCHECK ADD CONSTRAINT [FK_sched_process_product_sched_process] FOREIGN KEY ([sched_process_id]) REFERENCES [dbo].[sched_process] ([sched_process_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_process_product] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_process_product] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_process_product] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_process_product] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_process_product] TO [public]
GO
