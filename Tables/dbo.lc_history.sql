CREATE TABLE [dbo].[lc_history]
(
[timestamp] [timestamp] NOT NULL,
[allocation_no] [int] NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_dt] [datetime] NOT NULL,
[lc_alloc_total] [money] NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [lc_history_pk] ON [dbo].[lc_history] ([allocation_no], [voucher_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[lc_history] ADD CONSTRAINT [fk_lc_histo_ref_90851_lc_apvou] FOREIGN KEY ([voucher_no]) REFERENCES [dbo].[lc_apvoucher] ([voucher_no])
GO
GRANT REFERENCES ON  [dbo].[lc_history] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_history] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_history] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_history] TO [public]
GO
