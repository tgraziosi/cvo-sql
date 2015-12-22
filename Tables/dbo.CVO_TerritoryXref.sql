CREATE TABLE [dbo].[CVO_TerritoryXref]
(
[SCODE] [float] NULL,
[territory_code] [float] NULL,
[territory_desc] [float] NULL,
[Salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[User_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[security_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Status] [int] NULL,
[ship_via] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PresCouncil] [int] NULL,
[user_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ind0] ON [dbo].[CVO_TerritoryXref] ([territory_code], [Salesperson_code], [User_name]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [indx_terrxref_user] ON [dbo].[CVO_TerritoryXref] ([User_name], [security_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_TerritoryXref] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_TerritoryXref] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_TerritoryXref] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_TerritoryXref] TO [public]
GO
