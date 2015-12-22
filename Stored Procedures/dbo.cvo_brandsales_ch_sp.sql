SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec cvo_brandsales_ch_sp null, '06/10/2015', 'ch',  null, 0
-- 6/11/2015 - based on cvo_brandtracker_att_sp

CREATE procedure [dbo].[cvo_brandsales_ch_sp]
 @dto datetime = null -- todate
, @b varchar(1024) = null -- brand
, @t varchar(1024) = null -- territory
, @debug int = 0
as 

declare @datefrom datetime 
, @dateto datetime 
, @brand varchar(1024) 
, @terr varchar(1024) 

SELECT
@datefrom = null, 
@dateto = @dto, @brand = @b, @terr = @t
-- select @attrib = null

IF(OBJECT_ID('tempdb.dbo.#brand') is not null)  drop table #brand
create table #brand ( brand varchar(20))

IF(OBJECT_ID('tempdb.dbo.#terr') is not null)  drop table #terr
create table #terr ( terr varchar(10))

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

if @dateto is null select @dateto = DATEADD(DAY,0,DATEDIFF(DAY,0,GETDATE()))
if @datefrom is null select @datefrom = DATEADD(d,+1,DATEADD(YEAR,-1,@dateto))
IF @brand is null select @brand = 'ch'

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
, bb.net_sales
, t.net_sales tot_net_sales

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
, sum(anet) Net_sales

from #brand b
inner join inv_master i on b.brand = i.category
inner join inv_master_add ia on ia.part_no = i.part_no
inner join cvo_sbm_details sbm on sbm.part_no = i.part_no
where 1=1
and i.type_code in ('frame','sun')
and yyyymmdd between @datefrom and @dateto
group by b.brand
, ISNULL(ia.category_2,'')
, customer
, ship_to
) as bb on bb.customer = ar.customer_code and bb.ship_to = ar.ship_to_code

left outer join
( select 'Total' as Brand
, customer
, ship_to
, sum(anet) Net_sales
from inv_master i 
inner join inv_master_add ia on ia.part_no = i.part_no
inner join cvo_sbm_details sbm on sbm.part_no = i.part_no
inner join armaster ar on ar.customer_code = sbm.customer and ar.ship_to_code = sbm.ship_to
where 1=1
and i.type_code in ('frame','sun')
and yyyymmdd between @datefrom and @dateto
group by customer, ship_to
) as t on t.customer = ar.customer_code and t.ship_to = ar.ship_to_code
where ar.address_type <> 9

--IF(OBJECT_ID('tempdb.dbo.#newrea') is not null)  drop table #newrea

--create table #newrea
--( newrea varchar(3),
-- customer_code varchar(10), 
-- ship_to_code varchar(10),
-- firstst_new datetime,
-- prevst_new datetime
-- )

--declare @last_id int, @cust varchar(10), @ship_to varchar(10)
--	, @br varchar(20)

--select @last_id = min(id) from #t
--select @cust = customer_code, @ship_to = ship_to_code
--	, @br = brand
--	FROM #t where id = @last_id

--while @last_id is not null
--begin
--	-- get new/reactivated status
--	insert into #newrea exec cvo_newreacust_sp @cust, @ship_to


--	select @last_id = min(id) From #t where id > @last_id
--	select @cust = customer_code, @ship_to = ship_to_code
--	, @br = brand
--	FROM #t where id = @last_id

--end

--if @debug = 1 select * From #newrea

select #t.id
,#t.territory_code
,#t.customer_code
,#t.ship_to_code
, t_rank.r
,#t.address_name
,#t.city
,#t.brand
,gender = REPLACE(REPLACE(#t.gender,'-adult',''),'-child','')
,#t.Net_sales
,tot_net_sales = CASE WHEN id = 1 THEN #t.tot_net_sales ELSE 0 end
--, isnull(#newrea.newrea,'') newrea
, c.description brand_name
, dbo.calculate_region_fn(#t.territory_code) region
, @datefrom datefrom , @dateto dateto
 From  #t 
 --left outer join #newrea on #t.customer_code = #newrea.customer_code 
 --	and #t.ship_to_code = #newrea.ship_to_code
 inner join category c on c.kys = #t.brand
 LEFT OUTER JOIN
 ( SELECT territory_code, customer_code, ship_to_code, SUM(net_sales) sum_net, r = ROW_NUMBER() over (partition BY territory_code ORDER BY SUM(net_sales) DESC)
 FROM #t GROUP BY territory_code, customer_code, ship_to_code 
 ) t_rank ON t_rank.customer_code = #t.customer_code AND t_rank.ship_to_code = #t.ship_to_code

 where
(net_sales <> 0)
 order by customer_code

 --select * From #t where customer_code = '038305'
 --select * From #newrea where customer_code = '038305'
GO
