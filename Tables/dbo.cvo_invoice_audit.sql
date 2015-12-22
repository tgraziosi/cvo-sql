CREATE TABLE [dbo].[cvo_invoice_audit]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_value] [decimal] (20, 8) NULL,
[tax_value] [decimal] (20, 8) NULL,
[freight_value] [decimal] (20, 8) NULL,
[discount_value] [decimal] (20, 8) NULL,
[order_total] [decimal] (20, 8) NULL,
[printed_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_invoice_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_invoice_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_invoice_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_invoice_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_invoice_audit] TO [public]
GO
