CREATE TABLE [dbo].[esc_Global_Ship]
(
[customer_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [float] NULL,
[address_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[short_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_sort3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tlx_twx] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_1] [float] NULL,
[tax_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trade_discount_percent] [float] NULL,
[credit_limit] [float] NULL,
[ship_complete_flag] [float] NULL,
[resale_num] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[valid_payer_flag] [float] NULL,
[valid_soldto_flag] [float] NULL,
[valid_shipto_flag] [float] NULL,
[payer_soldto_rel_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[across_na_flag] [float] NULL,
[date_opened] [datetime] NULL,
[added_by_user_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postal_code] [float] NULL,
[country] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[esc_Global_Ship] TO [public]
GO
GRANT INSERT ON  [dbo].[esc_Global_Ship] TO [public]
GO
GRANT DELETE ON  [dbo].[esc_Global_Ship] TO [public]
GO
GRANT UPDATE ON  [dbo].[esc_Global_Ship] TO [public]
GO
