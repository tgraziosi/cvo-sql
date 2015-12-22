CREATE TABLE [dbo].[gltcrates]
(
[timestamp] [timestamp] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[external_tax_code] [varchar] (13) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stateCode] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zipCode] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[geoCode] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stateCityName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stateCitySalesRate] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cityTransitSalesRate] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[countyName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[countyCode] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[countySalesRate] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[countyTransitSalesRate] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[combinedSalesRate] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cityAdmin] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[countyAdmin] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltcrates] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcrates] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcrates] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcrates] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcrates] TO [public]
GO
