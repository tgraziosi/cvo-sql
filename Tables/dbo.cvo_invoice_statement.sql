CREATE TABLE [dbo].[cvo_invoice_statement]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[date_statement] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_invoice_statement] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_invoice_statement] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_invoice_statement] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_invoice_statement] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_invoice_statement] TO [public]
GO
