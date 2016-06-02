CREATE TABLE [dbo].[CVO_promotions]
(
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_start_date] [datetime] NULL,
[promo_end_date] [datetime] NULL,
[commission] [decimal] (6, 4) NULL,
[order_discount] [decimal] (6, 2) NULL,
[payment_terms] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rebate_start_date] [datetime] NULL,
[rebate_end_date] [datetime] NULL,
[rebate_discount_per] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rebate_discount_amt] [decimal] (6, 4) NULL,
[rebate_credit] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[free_shipping] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[list] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[commissionable] [smallint] NULL,
[order_type] [smallint] NULL,
[frequency] [int] NULL,
[review_ship_to] [smallint] NULL,
[subscription] [smallint] NULL,
[designation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_designation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ignore_for_credit_pricing] [smallint] NULL,
[shipping_method] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subscription_designation_code_primary_only] [smallint] NULL,
[promo_designation_code_primary_only] [smallint] NULL,
[debit_promo] [smallint] NULL,
[debit_promo_percentage] [decimal] (5, 2) NULL,
[debit_promo_amount] [decimal] (20, 8) NULL,
[drawdown_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drawdown_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drawdown_promo] [smallint] NULL,
[drawdown_expiry_days] [int] NULL,
[frequency_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[annual_program] [smallint] NULL,
[season_program] [smallint] NULL,
[backorder_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_discount_amount] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_promotions] ON [dbo].[CVO_promotions] ([promo_id], [promo_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_promotions] TO [public]
GO
