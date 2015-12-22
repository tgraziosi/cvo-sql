CREATE TABLE [dbo].[CVO_CountryXref]
(
[CName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_CountryXref] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_CountryXref] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_CountryXref] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_CountryXref] TO [public]
GO
