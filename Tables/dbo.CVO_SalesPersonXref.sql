CREATE TABLE [dbo].[CVO_SalesPersonXref]
(
[SCODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Salesperson_Code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesPerson_Name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_SalesPersonXref] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_SalesPersonXref] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_SalesPersonXref] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_SalesPersonXref] TO [public]
GO
