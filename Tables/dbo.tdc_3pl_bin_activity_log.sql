CREATE TABLE [dbo].[tdc_3pl_bin_activity_log]
(
[tran_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_3pl_b__tran___0C0621D3] DEFAULT (getdate()),
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_ext] [int] NULL,
[receipt_no] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_bin_activity_log_idx1] ON [dbo].[tdc_3pl_bin_activity_log] ([tran_date], [trans], [expert], [location], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_bin_activity_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_bin_activity_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_bin_activity_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_bin_activity_log] TO [public]
GO
