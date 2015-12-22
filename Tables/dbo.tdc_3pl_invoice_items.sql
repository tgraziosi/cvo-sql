CREATE TABLE [dbo].[tdc_3pl_invoice_items]
(
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contract_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_part_desc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[formula] [varchar] (7650) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_invoice_items_idx1] ON [dbo].[tdc_3pl_invoice_items] ([cust_code], [ship_to], [contract_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_invoice_items] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_invoice_items] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_invoice_items] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_invoice_items] TO [public]
GO
