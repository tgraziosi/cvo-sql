CREATE TABLE [dbo].[CVO_debit_promo_customer_hdr]
(
[hdr_rec_id] [int] NOT NULL IDENTITY(1, 1),
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[debit_promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[debit_promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[drawdown_promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[drawdown_promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_date] [datetime] NOT NULL,
[expiry_date] [datetime] NOT NULL,
[amount] [decimal] (20, 8) NOT NULL,
[balance] [decimal] (20, 8) NOT NULL,
[available] [decimal] (20, 8) NOT NULL,
[open_orders] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_debit_promo_customer_hdr_inx02] ON [dbo].[CVO_debit_promo_customer_hdr] ([customer_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_debit_promo_customer_hdr_inx03] ON [dbo].[CVO_debit_promo_customer_hdr] ([customer_code], [drawdown_promo_id], [drawdown_promo_level]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_debit_promo_customer_hdr_inx01] ON [dbo].[CVO_debit_promo_customer_hdr] ([hdr_rec_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_debit_promo_customer_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_debit_promo_customer_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_debit_promo_customer_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_debit_promo_customer_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_debit_promo_customer_hdr] TO [public]
GO
