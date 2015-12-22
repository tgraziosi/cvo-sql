SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cvo_brand_kpi_QtySold_sp] 
@brand varchar(10), 
@rollingtomonth datetime,
@months int

-- exec cvo_brand_kpi_sp 'bcbg','10/31/2013', 1
-- 1 = one month by style within brand
-- 3 = 3 months by style within brand
-- 12 = 12 months rolling by brand

as 
begin
declare @ty datetime
declare @py datetime
select  @ty = (DATEADD(m, -@months, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
-- select @py = (DATEADD(m, -24, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
select  @rollingtomonth =      (DATEADD(dd, datediff(dd,0,@RollingToMonth) + 0,0))


Select *
,case 
when qty_ordered < 0 then '<0'
When qty_ordered between 0 and 14 Then '0-14'
When qty_ordered between 15 and 27 Then '15-27'
When qty_ordered between 28 and 56 Then '28-56'
When qty_ordered > 56 Then '>56' End AS ord_category
From
(
select customer customer_code, i.category Product_group,Sum(qnet) AS qty_ordered,
dbo.calculate_region_fn(a.territory_code) AS Region 
From cvo_sbm_details c (nolock) 
inner join inv_master i (nolock) on i.part_no = c.part_no
inner join inv_master_add ia (nolock) on ia.part_no = c.part_no
inner join armaster a (nolock) on a.customer_code = c.customer and a.ship_to_code = c.ship_to
-- CVO_productSalesDet_vw
Where i.type_code in ('Frame','Sun')
AND i.category IN (@Brand)
and c.yyyymmdd >= (DATEADD(m, -12, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
AND c.yyyymmdd < DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 1,0)
group by c.customer,i.category,dbo.calculate_region_fn(a.territory_code)
) temp

end -- end of procedure

GO
GRANT EXECUTE ON  [dbo].[cvo_brand_kpi_QtySold_sp] TO [public]
GO
