CREATE TABLE [dbo].[cvo_third_party_ship_to]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[tp_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_carrier] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_default] [int] NULL,
[tp_entered_date] [datetime] NULL,
[tp_entered_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tp_modified_date] [datetime] NULL,
[tp_modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_third_party_ship_to] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_third_party_ship_to] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_third_party_ship_to] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_third_party_ship_to] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_third_party_ship_to] TO [public]
GO
