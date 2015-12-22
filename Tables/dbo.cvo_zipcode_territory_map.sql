CREATE TABLE [dbo].[cvo_zipcode_territory_map]
(
[zipcode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rep] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rsm] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[epicor_territory] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[county] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ziplook] ON [dbo].[cvo_zipcode_territory_map] ([zipcode], [epicor_territory], [region_code]) ON [PRIMARY]
GO
