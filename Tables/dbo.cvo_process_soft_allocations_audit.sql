CREATE TABLE [dbo].[cvo_process_soft_allocations_audit]
(
[allocation_date] [datetime] NULL,
[cons_no] [int] NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[perc_allocated] [decimal] (20, 8) NULL,
[error_messages] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_process_soft_allocations_aud_032814] ON [dbo].[cvo_process_soft_allocations_audit] ([order_no], [order_ext], [error_messages]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_process_soft_allocations_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_process_soft_allocations_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_process_soft_allocations_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_process_soft_allocations_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_process_soft_allocations_audit] TO [public]
GO
