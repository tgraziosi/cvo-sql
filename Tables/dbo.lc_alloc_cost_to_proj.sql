CREATE TABLE [dbo].[lc_alloc_cost_to_proj]
(
[timestamp] [timestamp] NOT NULL,
[allocation_no] [int] NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_no] [int] NOT NULL,
[cost_to_cd] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[project] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[seq_no] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [lc_alloc_cost_to_proj_pk] ON [dbo].[lc_alloc_cost_to_proj] ([allocation_no], [voucher_no], [receipt_no], [cost_to_cd], [seq_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[lc_alloc_cost_to_proj] ADD CONSTRAINT [lc_alloc_cost_to_proj_lc_alloc_cost_to_fk1] FOREIGN KEY ([allocation_no], [voucher_no], [receipt_no], [cost_to_cd]) REFERENCES [dbo].[lc_alloc_cost_to] ([allocation_no], [voucher_no], [receipt_no], [cost_to_cd])
GO
GRANT REFERENCES ON  [dbo].[lc_alloc_cost_to_proj] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_alloc_cost_to_proj] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_alloc_cost_to_proj] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_alloc_cost_to_proj] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_alloc_cost_to_proj] TO [public]
GO
