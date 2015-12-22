CREATE TABLE [dbo].[HS_Shipto_tbl]
(
[cust_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_street] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_street2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_postcode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_country] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_fax] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_default] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_by_date] [datetime] NULL,
[modified_by_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[HS_Shipto_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[HS_Shipto_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[HS_Shipto_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[HS_Shipto_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[HS_Shipto_tbl] TO [public]
GO
