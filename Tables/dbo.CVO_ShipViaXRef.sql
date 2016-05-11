CREATE TABLE [dbo].[CVO_ShipViaXRef]
(
[SVIA] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_ShipViaXRef] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ShipViaXRef] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ShipViaXRef] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ShipViaXRef] TO [public]
GO