SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_customer_sales_by_month_vw] AS 

 select 
 customer,
 (select top 1 customer_name from arcust (nolock) where customer = arcust.customer_code) customer_name,
 X_MONTH,
 [month],
 [year],
 sum(asales)asales,
 sum(areturns)areturns,
 sum(asales)-sum(areturns) as anet,
 sum(qsales)qsales,
 sum(qreturns)qreturns,
 sum(qsales) - sum(qreturns) as qnet
 -- from #cvo_csbm_det
 FROM cvo_sbm_details
 group by customer, year, X_MONTH, [month]
GO
GRANT REFERENCES ON  [dbo].[cvo_customer_sales_by_month_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_customer_sales_by_month_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_customer_sales_by_month_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_customer_sales_by_month_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_customer_sales_by_month_vw] TO [public]
GO
