CREATE TABLE [dbo].[tdc_3pl_wo_resource_log]
(
[tran_date] [datetime] NOT NULL CONSTRAINT [DF__tdc_3pl_w__tran___2F4F5E10] DEFAULT (getdate()),
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expert] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NOT NULL,
[employee_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shift] [int] NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_ext] [int] NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rowid] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_wo_resource_log_idx1] ON [dbo].[tdc_3pl_wo_resource_log] ([tran_date], [trans], [expert], [location], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_wo_resource_log] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_wo_resource_log] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_wo_resource_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_wo_resource_log] TO [public]
GO
