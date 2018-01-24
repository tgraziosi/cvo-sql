SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- 8/18/2015 - when calculating FirstOrder units, don't qualify on promo/level, only on promo

-- exec cvo_brandtracker_pogo_sp '1/1/2015', null, 'op', 'pogocam', null, 0

CREATE procedure [dbo].[cvo_brandtracker_pogo_sp]
@df datetime = null -- fromdate
, @dto datetime = null -- todate
, @b varchar(1024) = null -- brand
, @a varchar(1024) = null -- attribute
, @t varchar(1024) = null -- territory
, @debug int = 0
as 

BEGIN

SET NOCOUNT ON 

declare @datefrom datetime 
, @dateto datetime 
, @brand varchar(1024) 
, @attrib varchar(1024)
, @terr varchar(1024) 

select @datefrom = @df, @dateto = @dto, @brand = @b, @terr = @t, @attrib = @a
-- select @attrib = null


declare @brand_tbl table ( brand varchar(20))
declare @terr_tbl table ( terr varchar(10))
DECLARE @attrib_tbl TABLE ( attrib varchar(20))

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

if @datefrom is null select @datefrom = '1/1/2017'
if @dateto is null select @dateto = getdate()
if @brand is null select @brand = 'OP'
IF @attrib IS NULL SELECT @attrib = 'pogocam'

if isnull(@brand,'') = ''
begin
	insert @brand_tbl (brand) 
	select distinct kys from dbo.category where void = 'n'
end
else
begin
	insert @brand_tbl (brand)
	select  distinct listitem from dbo.f_comma_list_to_table(@brand)
end

if isnull(@attrib,'') = ''
begin
	insert @attrib_tbl (attrib) 
	select distinct pa.attribute from dbo.cvo_part_attributes AS pa
	-- insert @attrib_tbl (attrib) values ('')
end
else
begin
	insert @attrib_tbl (attrib)
	select  distinct listitem from dbo.f_comma_list_to_table(@attrib)
end

if isnull(@terr,'') = ''
begin
	insert @terr_tbl (terr) 
	select distinct territory_code from armaster (nolock) where isnull(territory_code,'') > ''
end
else
begin
	insert @terr_tbl (terr)
	select  distinct listitem from dbo.f_comma_list_to_table(@terr)
end

-- if @debug = 1 select * from @attrib_tbl

select 
id = Row_Number() over( order by ar.customer_code, ar.ship_to_code ) 
, ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name
, ar.contact_name, ar.contact_phone, ar.contact_email
, promo_id = space(10)
, promo_level = space(20)
, bb.brand
, bb.attrib
, bb.first_order_date
-- , bb.first_order_ship
, bb.Most_recent_ship_date
, 0 as fo_units
, 0 AS fo_cameras
, 0 AS fo_other
, 0 as st_units
, 0 AS st_cameras
, 0 AS st_other
, bb.pc_units
, bb.rx_units
, bb.net_sales
, t.net_sales tot_net_sales

into #t

from
@terr_tbl terr inner join 
armaster ar (nolock) on  ar.territory_code = terr.terr
inner join cvo_armaster_all car (nolock) on ar.customer_code = car.customer_code
	and ar.ship_to_code = car.ship_to
inner join
(select b.brand, @ATTRIB attrib
, customer, ship_to
, min(dateordered) first_order_date
, max(sbm.yyyymmdd) Most_recent_ship_date -- change from FO ship date
, sum(case when isnull(sbm.promo_id,'') in ('pc','ff','style out') 
	then qsales else 0 end
	) pc_units
, sum(case when user_category like 'rx%' 
	and isnull(sbm.promo_id,'') not in ('pc','ff','style out')
	then qsales else 0 end
	 ) rx_units
, sum(anet) Net_sales

from @brand_tbl b
inner join inv_master i on b.brand = i.category
inner join inv_master_add ia on ia.part_no = i.part_no
inner join cvo_sbm_details sbm on sbm.part_no = i.part_no
where 1=1
and i.type_code in ('frame','sun','acc')
and exists (select 1 from cvo_part_attributes pa where pa.part_no = i.part_no and pa.attribute in (select attrib from @attrib_tbl) )
and yyyymmdd between @datefrom and @dateto
group by b.brand, case when @attrib is null then '' else isnull(ia.field_32,'') end, customer, ship_to
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
and i.type_code in ('frame','sun','acc')
and yyyymmdd between @datefrom and @dateto
group by customer, ship_to
) as t on t.customer = ar.customer_code and t.ship_to = ar.ship_to_code
where ar.address_type <> 9

IF(OBJECT_ID('tempdb.dbo.#newrea') is not null)  drop table #newrea

create table #newrea
( newrea varchar(3),
 customer_code varchar(10), 
 ship_to_code varchar(10),
 firstst_new datetime,
 prevst_new datetime
 )

declare @last_id int, @cust varchar(10), @ship_to varchar(10)
	, @br varchar(20), @att varchar(20)
	, @fo DATETIME, @fos datetime
	, @promo varchar(10)
	, @level varchar(20)
	, @units INT
    , @cameras INT
    , @other int

select @last_id = min(id) from #t
select @cust = customer_code, @ship_to = ship_to_code
	, @br = brand
	, @att = attrib
	, @fo = first_order_date 
	, @fos = Most_recent_ship_date 
	FROM #t where id = @last_id
	select @promo = null, @level = null, @units = 0, @cameras = 0, @other = 0

while @last_id is not null
begin
	-- get new/reactivated status
	insert into #newrea exec cvo_newreacust_sp @cust, @ship_to

	-- get promo id and units of first order
	select @promo = isnull(s.promo_id,'')
		, @level = isnull(s.promo_level,'')
		, @units = sum(isnull(case when i.type_code in ('frame','sun') then qsales else 0 end,0))
		, @cameras = sum(isnull(case when i.part_no = 'pogocam' then qsales else 0 end,0))
		, @other = sum(isnull(case when i.type_code in ('acc') and i.part_no <> 'pogocam' THEN qsales ELSE 0 END,0))
	from cvo_sbm_details s (nolock) 
	 inner join inv_master i (nolock) 
	    on i.part_no = s.part_no
	 inner join inv_master_add ia (nolock)
		on ia.part_no = s.part_no 
	 where s.customer = @cust 
	 and s.ship_to = @ship_to
	 and i.category = @br 
	 and exists (select 1 from cvo_part_attributes pa where pa.part_no = i.part_no and pa.attribute = isnull(@att,pa.attribute))
	 and s.dateordered = @fo
	 and s.user_category like 'ST%' and right(s.user_category,2) <> 'rb'
	 and isnull(s.promo_id,'') not in ('ff','pc','style out')
	 and i.type_code in ('frame','sun','acc')
	 group by isnull(s.promo_id,'') , isnull(s.promo_level,'')
	 -- 052615 - per HK show all orders -- having sum(qsales) > 4
	order by isnull(s.promo_id,'') asc

	update #t set promo_id = isnull(@promo,'')
	, promo_level = isnull(@level,'')
	, fo_units = isnull(@units,0)
	, fo_cameras = ISNULL(@cameras,0)
	, fo_other = ISNULL(@other,0)
	where #t.id = @last_id

	-- get ST units after the first order
	select @units = sum(isnull(case when i.type_code in ('frame','sun') then qsales else 0 end,0))
		, @cameras = sum(isnull(case when i.part_no = 'pogocam' then qsales else 0 end,0))
		, @other = sum(isnull(case when i.type_code in ('acc') and i.part_no <> 'pogocam' then qsales else 0 END,0))
	from cvo_sbm_details s (nolock) 
	 inner join inv_master i (nolock) 
	    on i.part_no = s.part_no
	 inner join inv_master_add ia (nolock)
		on ia.part_no = s.part_no 
	 where s.customer = @cust 
	 and s.ship_to = @ship_to
	 and i.category = @br 
	 and exists (select 1 from cvo_part_attributes pa where pa.part_no = i.part_no and pa.attribute = isnull(@att,pa.attribute))
	 and s.dateordered > @fo
	 and yyyymmdd between @datefrom and @dateto
	 and s.user_category like 'ST%' and right(s.user_category,2) <> 'rb'
	 and isnull(s.promo_id,'') not in ('ff','pc','style out')
	 and i.type_code in ('frame','sun','acc')

	  -- get RA units
	 select @units = @units - sum(isnull(case when i.type_code in ('frame','sun') then qreturns else 0 end,0))
		, @cameras = @cameras - sum(isnull(case when i.part_no = 'pogocam' then qreturns else 0 end,0))
		, @other = @other - sum(isnull(case when i.type_code in ('acc') and i.part_no <> 'pogocam' then qreturns else 0 END,0))
	 FROM cvo_sbm_details s (nolock) 
	 inner join inv_master i (nolock) 
	    on i.part_no = s.part_no
	 inner join inv_master_add ia (nolock)
		on ia.part_no = s.part_no 
	 where s.customer = @cust 
	 and s.ship_to = @ship_to
	 and i.category = @br 
	 and exists (select 1 from cvo_part_attributes pa where pa.part_no = i.part_no and pa.attribute = isnull(@att,pa.attribute))
	 and s.dateordered > @fo
	 and yyyymmdd between @datefrom and @dateto
	 and s.return_code = ''  -- RA returns only
	 and i.type_code in ('frame','sun','acc')

	 
	update #t set st_units = isnull(@units,0), st_cameras = ISNULL(@cameras,0), st_other = ISNULL(@other,0)
	where #t.id = @last_id

	select @last_id = min(id) From #t where id > @last_id
	select @cust = customer_code, @ship_to = ship_to_code
	, @br = brand
	, @att = attrib
	, @fo = first_order_date
	, @fos = Most_recent_ship_date from #t where id = @last_id
	select @promo = null, @level = null, @units = 0, @cameras = 0, @other = 0
end

if @debug = 1 select * From #newrea

select #t.id,
       #t.territory_code,
       #t.customer_code,
       #t.ship_to_code,
       #t.address_name,
       #t.contact_name,
       #t.contact_phone,
       #t.contact_email,
       #t.promo_id,
       #t.promo_level,
       #t.brand,
       #t.attrib,
       #t.first_order_date,
       #t.Most_recent_ship_date,
       #t.fo_units,
       #t.fo_cameras,
       #t.fo_other,
       #t.st_units,
       #t.st_cameras,
       #t.st_other,
       #t.pc_units,
       #t.rx_units,
       #t.net_sales,
       #t.tot_net_sales
, isnull(#newrea.newrea,'') NewRea
, c.description brand_name
, dbo.calculate_region_fn(#t.territory_code) region
 From  #t 
 left outer join #newrea on #t.customer_code = #newrea.customer_code 
	and #t.ship_to_code = #newrea.ship_to_code
 inner join category c on c.kys = #t.brand
 where
(fo_units <> 0 or st_units <> 0 or pc_units <> 0 or rx_units <> 0 or net_sales <> 0)
 order by customer_code

 --select * From #t where customer_code = '038305'
 --select * From #newrea where customer_code = '038305'


 END;


GO
