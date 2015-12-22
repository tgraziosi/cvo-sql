CREATE TABLE [dbo].[tdc_3pl_quote_assigned_labor_values]
(
[quote_id] [int] NULL,
[tran_id] [int] NULL,
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_quote_assigned_labor_values] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_quote_assigned_labor_values] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_quote_assigned_labor_values] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_quote_assigned_labor_values] TO [public]
GO
