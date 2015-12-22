CREATE TABLE [dbo].[tdc_3pl_qc_release_log]
(
[tran_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_3pl_q__tran___1A54412A] DEFAULT (getdate()),
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_key] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_no] [int] NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [int] NULL,
[receipt_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_qty] [decimal] (20, 8) NULL,
[reject_qty] [decimal] (20, 8) NULL,
[reason] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reject_reason] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowid] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_qc_release_log_idx1] ON [dbo].[tdc_3pl_qc_release_log] ([tran_date], [trans], [expert], [location], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_qc_release_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_qc_release_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_qc_release_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_qc_release_log] TO [public]
GO
