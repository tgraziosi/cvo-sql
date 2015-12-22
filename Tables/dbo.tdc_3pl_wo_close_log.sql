CREATE TABLE [dbo].[tdc_3pl_wo_close_log]
(
[tran_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_3pl_w__tran___2B7ECD2C] DEFAULT (getdate()),
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[employee_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shift] [int] NULL,
[prod_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowid] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_wo_close_log_idx1] ON [dbo].[tdc_3pl_wo_close_log] ([tran_date], [trans], [expert], [location], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_wo_close_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_wo_close_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_wo_close_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_wo_close_log] TO [public]
GO
