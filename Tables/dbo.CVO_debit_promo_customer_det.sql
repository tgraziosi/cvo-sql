CREATE TABLE [dbo].[CVO_debit_promo_customer_det]
(
[det_rec_id] [int] NOT NULL IDENTITY(1, 1),
[hdr_rec_id] [int] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[credit_amount] [decimal] (20, 8) NOT NULL,
[posted] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_debit_promo_customer_det_inx03] ON [dbo].[CVO_debit_promo_customer_det] ([order_no], [ext], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_debit_promo_customer_det] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_debit_promo_customer_det] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_debit_promo_customer_det] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_debit_promo_customer_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_debit_promo_customer_det] TO [public]
GO
