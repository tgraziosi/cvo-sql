CREATE TABLE [dbo].[CVO_ShipTos]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[customer_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[contact_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_phone] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tlx_twx] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trade_discount_percent] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_limit] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_complete_flag] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resale_num] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[valid_payer_flag] [float] NULL,
[valid_soldto_flag] [float] NULL,
[valid_shipto_flag] [float] NULL,
[payer_soldto_rel_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[across_na_flag] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_opened] [datetime] NULL,
[added_by_user_name] [nvarchar] (266) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postal_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_ShipTos] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ShipTos] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ShipTos] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ShipTos] TO [public]
GO
