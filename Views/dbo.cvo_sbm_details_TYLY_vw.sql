SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_sbm_details_TYLY_vw] AS

SELECT s.customer,
       s.ship_to,
       s.customer_name,
       s.part_no,
       s.promo_id,
       s.promo_level,
       s.return_code,
       s.user_category,
       s.location,
       s.c_month,
       s.c_year,
       s.X_MONTH,
       s.month,
       s.year,
       s.asales,
       s.areturns,
       s.anet,
       s.qsales,
       s.qreturns,
       s.qnet,
       s.csales,
       s.lsales,
       s.yyyymmdd,
       s.DateOrdered,
       s.isCL,
       s.isBO,
       s.slp,
	   ar.territory_code,
	   car.door,
	   ar.addr_sort1 customer_type,
	   i.category brand,
	   ia.field_2 model,
	   i.type_code
	   
FROM cvo_sbm_details s (nolock)
JOIN armaster ar (nolock) ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
JOIN cvo_armaster_all car (nolock) ON car.customer_code = ar.customer_code AND car.ship_to = ar.ship_to_code
JOIN inv_master i (NOLOCK) ON i.part_no = s.part_no
JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no

WHERE s.YEAR >= DATEPART(year, DATEADD(YEAR,-1,GETDATE()))
GO
GRANT SELECT ON  [dbo].[cvo_sbm_details_TYLY_vw] TO [public]
GO
