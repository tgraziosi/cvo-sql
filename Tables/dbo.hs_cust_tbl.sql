CREATE TABLE [dbo].[hs_cust_tbl]
(
[id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_street] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_street2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_postcode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_country] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_fax] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_street] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_street2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_postcode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_country] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_fax] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[paymentTerms] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shippingMethod] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customerGroup] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userGroup] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[taxID] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_by_date] [datetime] NULL,
[modified_by_date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[hs_cust_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[hs_cust_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[hs_cust_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[hs_cust_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[hs_cust_tbl] TO [public]
GO
