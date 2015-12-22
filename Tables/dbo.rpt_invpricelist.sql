CREATE TABLE [dbo].[rpt_invpricelist]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_a] [decimal] (20, 8) NULL,
[price_b] [decimal] (20, 8) NULL,
[price_c] [decimal] (20, 8) NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_rate] [decimal] (20, 8) NULL,
[promo_expires] [datetime] NULL,
[promo_entered] [datetime] NULL,
[account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_d] [decimal] (20, 8) NULL,
[price_e] [decimal] (20, 8) NULL,
[price_f] [decimal] (20, 8) NULL,
[qty_a] [decimal] (20, 8) NULL,
[qty_b] [decimal] (20, 8) NULL,
[qty_c] [decimal] (20, 8) NULL,
[qty_d] [decimal] (20, 8) NULL,
[qty_e] [decimal] (20, 8) NULL,
[qty_f] [decimal] (20, 8) NULL,
[curr_key] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_3] [int] NULL,
[group_4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_date_cutoff] [int] NULL,
[org_level] [int] NULL,
[loc_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_curr_precision] [smallint] NULL,
[g_rounding_factor] [int] NULL,
[g_position] [int] NULL,
[g_neg_num_format] [int] NULL,
[g_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_symbol_space] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_dec_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_thou_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invpricelist] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invpricelist] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invpricelist] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invpricelist] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invpricelist] TO [public]
GO
