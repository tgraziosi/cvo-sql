CREATE TABLE [dbo].[tdc_3pl_quote_templates_used_tbl]
(
[quote_id] [int] NULL,
[template_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[template_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_quote_templates_used_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_quote_templates_used_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_quote_templates_used_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_quote_templates_used_tbl] TO [public]
GO
