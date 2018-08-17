CREATE TABLE [dbo].[cvo_tdc_log_archive_tbl]
(
[tran_date] [datetime] NOT NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[data] [varchar] (7500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_log_idx_arch_1] ON [dbo].[cvo_tdc_log_archive_tbl] ([tran_date], [location], [part_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_tdc_log_archive_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_tdc_log_archive_tbl] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_tdc_log_archive_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_tdc_log_archive_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_tdc_log_archive_tbl] TO [public]
GO
