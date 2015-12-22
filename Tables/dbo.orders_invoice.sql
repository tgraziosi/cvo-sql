CREATE TABLE [dbo].[orders_invoice]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord_inv_idx2] ON [dbo].[orders_invoice] ([doc_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ordinvoice] ON [dbo].[orders_invoice] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord_inv_idx1] ON [dbo].[orders_invoice] ([trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[orders_invoice] TO [public]
GO
GRANT SELECT ON  [dbo].[orders_invoice] TO [public]
GO
GRANT INSERT ON  [dbo].[orders_invoice] TO [public]
GO
GRANT DELETE ON  [dbo].[orders_invoice] TO [public]
GO
GRANT UPDATE ON  [dbo].[orders_invoice] TO [public]
GO
