CREATE TABLE [dbo].[tdc_3pl_quote_invoice_items]
(
[quote_id] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_part_desc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[formula] [varchar] (7650) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_quote_invoice_items_idx1] ON [dbo].[tdc_3pl_quote_invoice_items] ([quote_id], [line_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_quote_invoice_items] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_quote_invoice_items] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_quote_invoice_items] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_quote_invoice_items] TO [public]
GO
