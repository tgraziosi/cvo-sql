SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_csbm_shipto_daily_vw] AS 

 SELECT 
 customer,
 ship_to,
 (select top 1 address_name from armaster (nolock) 
  where customer = armaster.customer_code and ship_to_code=ship_to) customer_name,
 X_MONTH,
 [month],
 [year],
 sum(asales)asales,
 sum(areturns)areturns,
 sum(asales)-sum(areturns) as anet,
 sum(qsales)qsales,
 sum(qreturns)qreturns,
 sum(qsales) - sum(qreturns) as qnet,
-- cast ((cast([x_month] as varchar(2))+'/01/'+cast([year] as varchar(4))) as datetime) as yyyymmdd 
 yyyymmdd
 from cvo_sbm_details
 group by customer, ship_to, year, X_MONTH, [month], yyyymmdd
GO
GRANT REFERENCES ON  [dbo].[cvo_csbm_shipto_daily_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_csbm_shipto_daily_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_csbm_shipto_daily_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_csbm_shipto_daily_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_csbm_shipto_daily_vw] TO [public]
GO
