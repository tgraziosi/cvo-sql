CREATE TABLE [dbo].[tdc_3pl_quote_templates_labor_details_tbl]
(
[quote_id] [int] NULL,
[template_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [int] NULL,
[category] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fee] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_quote_templates_labor_details_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_quote_templates_labor_details_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_quote_templates_labor_details_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_quote_templates_labor_details_tbl] TO [public]
GO
