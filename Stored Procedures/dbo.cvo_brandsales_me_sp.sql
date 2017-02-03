SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec cvo_brandsales_me_sp '2016', 'me',  null, 0
-- 6/11/2015 - based on cvo_brandtracker_att_sp

CREATE procedure [dbo].[cvo_brandsales_me_sp]
 @dto int = null -- todate
, @b varchar(1024) = null -- brand
, @t varchar(1024) = null -- territory
, @debug int = 0
as 

declare @datefrom datetime 
, @dateto datetime 
, @brand varchar(1024) 
, @terr varchar(1024) 
, @year int

SELECT
@datefrom = null, 
@dateto = @dto, @brand = @b, @terr = @t, @year = @dto
-- select @attrib = null

IF(OBJECT_ID('tempdb.dbo.#brand') is not null)  drop table #brand
create table #brand ( brand varchar(20))

IF(OBJECT_ID('tempdb.dbo.#terr') is not null)  drop table #terr
create table #terr ( terr varchar(10))

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

if @dateto is null select @dateto = DATEADD(DAY,0,DATEDIFF(DAY,0,GETDATE()))
if @datefrom is null select @datefrom = DATEADD(d,+1,DATEADD(YEAR,-1,@dateto))
IF @brand is null select @brand = 'me'

if isnull(@brand,'') = ''
begin
	insert #brand (brand) 
	select distinct kys from category where void = 'n'
end
else
begin
	insert #brand (brand)
	select  distinct listitem from dbo.f_comma_list_to_table(@brand)
end

if isnull(@terr,'') = ''
begin
	insert #terr (terr) 
	select distinct territory_code from armaster (nolock) where isnull(territory_code,'') > ''
end
else
begin
	insert #terr (terr)
	select  distinct listitem from dbo.f_comma_list_to_table(@terr)
end

select 
id = Row_Number() over( PARTITION BY ar.customer_code, ar.ship_to_code ORDER by ar.customer_code, ar.ship_to_code ) 
, ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name, ar.city
, bb.brand
, bb.gender
, bb.Net_sales_TY BRAND_NS_TY
, bb.Net_sales_LY BRAND_NS_LY
, bb.Net_sales_PY BRAND_NS_PY
, t.Net_sales_TY  NET_TY
, t.Net_sales_LY  NET_LY
, t.Net_sales_PY  NET_PY

into #t

from
#terr inner join 
armaster ar (nolock) on #terr.terr = ar.territory_code
inner join cvo_armaster_all car (nolock) on ar.customer_code = car.customer_code
	and ar.ship_to_code = car.ship_to
inner join
(select b.brand
, ISNULL(ia.category_2,'') gender
, customer, ship_to
, sum(CASE WHEN c_year = @year THEN anet ELSE 0 end) Net_sales_TY
, sum(CASE WHEN c_year = @year-1 THEN anet ELSE 0 end) Net_sales_LY
, sum(CASE WHEN c_year = @year-2 THEN anet ELSE 0 end) Net_sales_PY

from #brand b
inner join inv_master i on b.brand = i.category
inner join inv_master_add ia on ia.part_no = i.part_no
inner join cvo_sbm_details sbm on sbm.part_no = i.part_no
where 1=1
and i.type_code in ('frame','sun')
and c_year between @year - 2 AND @year
group by b.brand
, ISNULL(ia.category_2,'')
, customer
, ship_to
) as bb on bb.customer = ar.customer_code and bb.ship_to = ar.ship_to_code

left outer join
( select 'Total' as Brand
, customer
, ship_to
, sum(CASE WHEN c_year = @year THEN anet ELSE 0 end) Net_sales_TY
, sum(CASE WHEN c_year = @year-1 THEN anet ELSE 0 end) Net_sales_LY
, sum(CASE WHEN c_year = @year-2 THEN anet ELSE 0 end) Net_sales_PY

from inv_master i 
inner join inv_master_add ia on ia.part_no = i.part_no
inner join cvo_sbm_details sbm on sbm.part_no = i.part_no
inner join armaster ar on ar.customer_code = sbm.customer and ar.ship_to_code = sbm.ship_to
where 1=1
and i.type_code in ('frame','sun')
and c_year between @year-2 and @year
group by customer, ship_to
) as t on t.customer = ar.customer_code and t.ship_to = ar.ship_to_code
where ar.address_type <> 9


select #t.id
,#t.territory_code
,#t.customer_code
,#t.ship_to_code
, t_rank.r
,#t.address_name
,#t.city
,#t.brand
,gender = REPLACE(REPLACE(#t.gender,'-adult',''),'-child','')
,#t.BRAND_NS_TY
,#T.BRAND_NS_LY
,#T.BRAND_NS_PY
,NET_TY = CASE WHEN ID =  1 THEN #T.NET_TY ELSE 0 END
,NET_LY = CASE WHEN ID =  1 THEN #T.NET_LY ELSE 0 END
,NET_PY = CASE WHEN ID =  1 THEN #T.NET_PY ELSE 0 END
, c.description brand_name
, dbo.calculate_region_fn(#t.territory_code) region
 From  #t 
 inner join category c on c.kys = #t.brand
 LEFT OUTER JOIN
 ( SELECT territory_code, customer_code, ship_to_code, SUM(BRAND_NS_TY) sum_net, r = ROW_NUMBER() over (partition BY territory_code ORDER BY SUM(BRAND_NS_TY) DESC)
 FROM #t GROUP BY territory_code, customer_code, ship_to_code 
 ) t_rank ON t_rank.customer_code = #t.customer_code AND t_rank.ship_to_code = #t.ship_to_code

 where
(#T.BRAND_NS_TY + BRAND_NS_LY + BRAND_NS_PY <> 0)
 order by customer_code

 --select * From #t where customer_code = '038305'
 --select * From #newrea where customer_code = '038305'
GO
GRANT EXECUTE ON  [dbo].[cvo_brandsales_me_sp] TO [public]
GO
