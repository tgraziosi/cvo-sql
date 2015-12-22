CREATE TABLE [dbo].[ship_to]
(
[timestamp] [timestamp] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mailing_list] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_hold] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_no] [decimal] (20, 8) NULL,
[price_level] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[discount] [decimal] (20, 8) NULL,
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[si] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [shiptono] ON [dbo].[ship_to] ([cust_code], [ship_to_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ship_to] TO [public]
GO
GRANT SELECT ON  [dbo].[ship_to] TO [public]
GO
GRANT INSERT ON  [dbo].[ship_to] TO [public]
GO
GRANT DELETE ON  [dbo].[ship_to] TO [public]
GO
GRANT UPDATE ON  [dbo].[ship_to] TO [public]
GO
