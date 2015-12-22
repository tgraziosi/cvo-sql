SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_sales_by_brand_month_sp] as 
begin

-- exec [cvo_sales_by_brand_month_sp]
-- Sales by Brand by Month with New Doors

select 
case when s.brand in ('BCBG','ET','CH') THEN 'Premium'
     when s.brand in ('me','un','cvo','izod','izx','op','jmc','jc','pt')
      and s.kids = 'N' then 'Core'
     when s.kids = 'Y' then 'Children'
     else 'Unknown'
     end as BrandCat,
case when s.brand like 'iz%' then 'IZOD' ELSE  S.brand end as brand,
isnull((select description from category where kys = s.brand),'') brand_desc,
 s.c_month, s.c_year
,s.asales, s.qsales, s.areturns, s.qreturns
,s.anet, s.qnet
,s.cogs
,isnull(x.new_doors,0) new_doors

 from

-- Sales by Brand
(select i.category Brand,
case when ia.category_2 like '%child%' then 'Y' else 'N' end as Kids,
c_month,
c_year,
sum(isnull(asales,0)) asales,
sum(isnull(qsales,0)) qsales,
sum(isnull(areturns,0)) areturns,
sum(isnull(qreturns,0)) qreturns,
sum(isnull(anet,0)) anet,
sum(isnull(qnet,0)) qnet
,sum(isnull(qnet,0)) * (inv.std_cost+inv.std_ovhd_dolrs+inv.std_util_dolrs) as cogs
from 
inv_master i (nolock) 
inner join inv_master_add ia (nolock) on ia.part_no = i.part_no
inner join inv_list inv (nolock) on inv.part_no = i.part_no and inv.location = '001'
inner join cvo_sbm_details a (nolock)  on a.part_no = i.part_no
where i.type_code in ('frame','sun') 
-- and inv.location = '001'
group by i.category, case when ia.category_2 like '%child%' then 'Y' else 'N' end,
c_month, c_year
, inv.std_cost, inv.std_ovhd_dolrs, inv.std_util_dolrs
) s

left outer join

-- New Doors
(select -- x
ffs.brand, ffs.new_doors, ffs.c_month, ffs.c_year from
(
SELECT -- ffs
fs.BRAND, COUNT(fs.CUSTOMER) NEW_DOORS, DATEPART(MONTH,fs.FIRST_SALE) C_MONTH, 
DATEPART(YEAR,fs.FIRST_SALE) C_YEAR FROM
( 
SELECT -- fs
I.CATEGORY BRAND,
A.CUSTOMER,
MIN(YYYYMMDD) FIRST_SALE
FROM 
inv_master i (nolock) 
inner join inv_master_add ia (nolock) on ia.part_no = i.part_no
inner join cvo_sbm_details a (nolock) on a.part_no = i.part_no
where i.type_code in ('frame','sun') 
and a.ship_to = '' and a.asales <> 0
group by i.category, A.CUSTOMER
) fs
group by fs.brand,  DATEPART(MONTH,fs.FIRST_SALE), DATEPART(YEAR,fs.FIRST_SALE)
) ffs 
) x

on s.brand = x.brand and s.c_month = x.c_month and s.c_year = x.c_year

end
GO
GRANT EXECUTE ON  [dbo].[cvo_sales_by_brand_month_sp] TO [public]
GO
