CREATE TABLE [dbo].[rpt_arcust_ship]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcust_ship] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcust_ship] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcust_ship] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcust_ship] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcust_ship] TO [public]
GO
