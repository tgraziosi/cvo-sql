CREATE TABLE [dbo].[cvo_order_third_party_ship_to]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[third_party_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_address_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_address_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_address_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_address_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_address_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_address_6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_order_third_party_ship_to] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_third_party_ship_to] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_third_party_ship_to] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_third_party_ship_to] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_third_party_ship_to] TO [public]
GO
