CREATE TABLE [dbo].[cust_carrier_account]
(
[timestamp] [timestamp] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[freight_allow_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[routing] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_cust_carrier_account] ON [dbo].[cust_carrier_account] ([cust_code], [ship_to], [freight_allow_type], [routing]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cust_carrier_account] TO [public]
GO
GRANT SELECT ON  [dbo].[cust_carrier_account] TO [public]
GO
GRANT INSERT ON  [dbo].[cust_carrier_account] TO [public]
GO
GRANT DELETE ON  [dbo].[cust_carrier_account] TO [public]
GO
GRANT UPDATE ON  [dbo].[cust_carrier_account] TO [public]
GO
