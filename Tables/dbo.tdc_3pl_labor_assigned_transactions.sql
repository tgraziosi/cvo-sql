CREATE TABLE [dbo].[tdc_3pl_labor_assigned_transactions]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_id] [int] NOT NULL,
[fee] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_labor_assigned_transactions_idx2] ON [dbo].[tdc_3pl_labor_assigned_transactions] ([category], [tran_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_labor_assigned_transactions_idx1] ON [dbo].[tdc_3pl_labor_assigned_transactions] ([location], [template_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_labor_assigned_transactions] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_labor_assigned_transactions] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_labor_assigned_transactions] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_labor_assigned_transactions] TO [public]
GO
