SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- select * from cvo_brandunitsalesbymonth_vw

CREATE view [dbo].[cvo_BrandUnitSalesByMonth_vw] as
select 
i.category as Brand,
ia.field_2 as Model,
i.type_code type,
min(ia.field_28) pom_date,
datepart(yyyy,yyyymmdd) as [year],
sum(isnull((case a.x_month when 1 then a.qnet end), 0)) as jan,
sum(isnull((case a.x_month when 2 then a.qnet end), 0)) as feb,
sum(isnull((case a.x_month when 3 then a.qnet end), 0)) as mar,
sum(isnull((case a.x_month when 4 then a.qnet end), 0)) as apr,
sum(isnull(case a.x_month when 5 then a.qnet end, 0)) as may,
sum(isnull(case a.x_month when 6 then a.qnet end, 0)) as jun,
sum(isnull(case a.x_month when 7 then a.qnet end, 0)) as jul,
sum(isnull(case a.x_month when 8 then a.qnet end, 0)) as aug,
sum(isnull(case a.x_month when 9 then a.qnet end, 0)) as sep,
sum(isnull(case a.x_month when 10 then a.qnet end, 0)) as oct,
sum(isnull(case a.x_month when 11 then a.qnet end, 0)) as nov,
sum(isnull(case a.x_month when 12 then a.qnet end, 0))as dec,
sum(isnull(a.qnet,0)) as Total
, location

from cvo_sbm_details a (nolock)  
inner join inv_master i (nolock) on i.part_no = a.part_no
inner join inv_master_add ia (nolock) on ia.part_no = a.part_no
where i.type_code in ('frame','sun') 

group by i.category, ia.field_2, i.type_code, datepart(yyyy,a.yyyymmdd), location
-- group by brand, model, type_code, datepart(yyyy,yyyymmdd)







GO
GRANT SELECT ON  [dbo].[cvo_BrandUnitSalesByMonth_vw] TO [public]
GO
