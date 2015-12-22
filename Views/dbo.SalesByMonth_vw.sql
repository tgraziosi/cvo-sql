SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [dbo].[SalesByMonth_vw]
AS
SELECT Brand,Model,yyyymmdd, X_MONTH
,Sum(asales) AS TotalSales
FROM  cvo_psbm
Group By Brand,Model,yyyymmdd,X_MONTH
GO
