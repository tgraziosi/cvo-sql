CREATE TABLE [dbo].[cvo_order_invoice]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[inv_number] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_order_invoice_ind0] ON [dbo].[cvo_order_invoice] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_order_invoice] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_invoice] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_invoice] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_invoice] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_invoice] TO [public]
GO
