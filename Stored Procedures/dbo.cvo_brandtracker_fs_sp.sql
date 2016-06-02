SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- 8/18/2015 - when calculating FirstOrder units, don't qualify on promo/level, only on promo

-- exec cvo_brandtracker_fs_sp '1/1/2015', null, 'as', null, 50505, 'aspire', '1.1,1,2,3,launch', null, null, 0

CREATE procedure [dbo].[cvo_brandtracker_fs_sp]
@df datetime = null -- fromdate
, @dto datetime = null -- todate
, @b varchar(1024) = null -- brand
, @a varchar(1024) = null -- attribute
, @t varchar(1024) = null -- territory
, @bp VARCHAR(1024) = NULL -- buyin promo list
, @bl VARCHAR(1024) = NULL -- buyin levels
, @p VARCHAR(1024) = NULL -- highlight promo
, @l VARCHAR(1024) = NULL -- highlight level
, @debug int = 0
as 

SET NOCOUNT ON

declare @datefrom datetime 
, @dateto datetime 
, @brand varchar(1024) 
, @attrib varchar(1024)
, @terr varchar(1024) 
, @fpromo_id VARCHAR(1024)
, @fpromo_level VARCHAR(1024)
, @bpromo_id VARCHAR(1024)
, @bpromo_level VARCHAR(1024)


select @datefrom = @df, @dateto = @dto, @brand = @b, @terr = @t, @attrib = @a, @fpromo_id = @p, @fpromo_level = @l, @bpromo_id = @bp, @bpromo_level = @bl
-- select @attrib = null

IF(OBJECT_ID('tempdb.dbo.#brand') is not null)  drop table #brand
create table #brand ( brand varchar(20))

IF(OBJECT_ID('tempdb.dbo.#terr') is not null)  drop table #terr
create table #terr ( terr varchar(10))

IF(OBJECT_ID('tempdb.dbo.#attrib') is not null)  drop table #attrib
create table #attrib ( attrib varchar(20))

IF(OBJECT_ID('tempdb.dbo.#bp') is not null)  drop table #bp
create table #bp ( bp varchar(10))

IF(OBJECT_ID('tempdb.dbo.#bl') is not null)  drop table #bl
create table #bl ( bl VARCHAR(10))

IF(OBJECT_ID('tempdb.dbo.#fp') is not null)  drop table #fp
create table #fp ( fp varchar(10))

IF(OBJECT_ID('tempdb.dbo.#fl') is not null)  drop table #fl
create table #fl ( fl varchar(10))

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

if @datefrom is null select @datefrom = '1/1/2015'
if @dateto is null select @dateto = getdate()
if @brand is null select @brand = 'as'

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

if isnull(@attrib,'') = ''
begin
	insert #attrib (attrib) 
	select distinct field_32 from inv_master_add
	-- insert #attrib (attrib) values ('')
end
else
begin
	insert #attrib (attrib)
	select  distinct listitem from dbo.f_comma_list_to_table(@attrib)
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

if isnull(@bpromo_id,'') = ''
begin
	insert #BP (BP) 
	select distinct PROMO_id from cvo_promotions (nolock) where isnull(promo_id,'') > '' AND void <> 'v'
end
else
begin
	insert #bp (bp)
	select  distinct listitem from dbo.f_comma_list_to_table(@bpromo_id)
end

IF isnull(@bpromo_level,'') = ''
begin
	insert #Bl (Bl) 
	select distinct PROMO_id from cvo_promotions (nolock) 
	JOIN #bp ON promo_id = #bp.bp
	WHERE isnull(promo_level,'') > '' 
end
else
begin
	insert #bl (bl)
	select  distinct listitem 
	FROM dbo.f_comma_list_to_table(@bpromo_level)
END


if isnull(@fpromo_id,'') = ''
begin
	insert #fP (fP) 
	select distinct PROMO_id from cvo_promotions (nolock) where isnull(promo_id,'') > '' AND void <> 'v'
end
else
begin
	insert #fp (fp)
	select  distinct listitem from dbo.f_comma_list_to_table(@fpromo_id)
end

IF isnull(@fpromo_level,'') = ''
begin
	insert #fl (fl) 
	select distinct PROMO_id from cvo_promotions (nolock) 
	JOIN #fp ON promo_id = #fp.fp
	WHERE isnull(promo_level,'') > '' 
end
else
begin
	insert #fl (fl)
	select  distinct listitem 
	FROM dbo.f_comma_list_to_table(@fpromo_level)
END


-- get first order information based on buy-in promo list

select 
ar.territory_code, ar.customer_code,  ar.customer_name
, ar.contact_name, ar.contact_phone, ar.contact_email
, bb.promo_id
, bb.promo_level
, bb.brand
, BB.type_code
, bb.attrib
, bb.first_order_date
, bb.first_order_ship
, CAST(NULL AS DATETIME) AS highlight_ship_date

into #t

from
#terr inner join 
arcust ar (nolock) on #terr.terr = ar.territory_code

inner join
(select b.brand, i.type_code, CASE WHEN @attrib is NULL THEN '' ELSE ISNULL(ia.field_32,'') END AS attrib
, customer
, MIN(ISNULL(sbm.promo_id,'')) promo_id
, MIN(ISNULL(sbm.promo_level,'')) promo_level
, min(sbm.dateordered) first_order_date
, MIN(sbm.yyyymmdd) first_order_ship

from #brand b
inner join inv_master i on b.brand = i.category
inner join inv_master_add ia on ia.part_no = i.part_no
inner join #attrib a on a.attrib = ISNULL(ia.field_32,'')
inner join cvo_sbm_details sbm on sbm.part_no = i.part_no
INNER JOIN #bp ON #bp.bp = sbm.promo_id
INNER JOIN #bl ON #bl.bl = sbm.promo_level
where 1=1
and i.type_code in ('frame','sun')
-- and sbm.user_category like 'ST%' 
AND right(sbm.user_category,2) <> 'rb'
and ISNULL(sbm.promo_id,'') NOT IN ('pc','ff','style out') 
-- and dateordered between @datefrom and @dateto
and sbm.yyyymmdd between @datefrom and @dateto
group BY b.brand, i.type_code, CASE WHEN @attrib is NULL THEN '' ELSE ISNULL(ia.field_32,'') END , customer
) as bb on bb.customer = ar.customer_code 

IF @debug = 1 SELECT * FROM #t WHERE customer_code = '045455'

SELECT 
 #t.customer_code
 ,#t.type_code
, sum(ISNULL(qnet,0)) units
, 'BI' sale_type
INTO #v
FROM
 #t
inner join inv_master i on i.category=#t.brand AND i.type_code = #t.type_code
inner join inv_master_add ia on ia.part_no = i.part_no
inner join #attrib a on a.attrib = ISNULL(ia.field_32,'')
INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code AND sbm.part_no = i.part_no
INNER JOIN #bp ON #bp.bp = sbm.promo_id
INNER JOIN #bl ON #bl.bl = sbm.promo_level
where 1=1
and ISNULL(sbm.promo_id,'') NOT IN ('pc','ff','style out') 
AND RIGHT(sbm.user_category,2) <> 'rb' 
and sbm.DateOrdered = #t.first_order_date
GROUP BY 
#t.customer_code, #t.type_code


INSERT INTO #v
SELECT 
 #t.customer_code
 ,#t.type_code
, sum(ISNULL(qnet,0)) units
, 'RX' sale_type
FROM
 #t
inner join inv_master i on i.category=#t.brand AND i.type_code = #t.type_code
inner join inv_master_add ia on ia.part_no = i.part_no
inner join #attrib a on a.attrib = ISNULL(ia.field_32,'')
INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code AND sbm.part_no = i.part_no
where 1=1
and ISNULL(sbm.promo_id,'') NOT IN ('pc','ff','style out') 
AND LEFT(sbm.user_category,2) in ('rx') AND RIGHT(sbm.user_category,2) <> 'rb'
and sbm.yyyymmdd between DATEADD(dd,1,#t.first_order_ship) and @dateto
GROUP BY 
#t.customer_code, #t.type_code

INSERT INTO #v
SELECT 
 #t.customer_code
 ,#t.type_code
, sum(ISNULL(qnet,0)) units
, 'PC' sale_type
FROM
 #t
inner join inv_master i on i.category=#t.brand AND i.type_code = #t.type_code
inner join inv_master_add ia on ia.part_no = i.part_no
inner join #attrib a on a.attrib = ISNULL(ia.field_32,'')
INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code AND sbm.part_no = i.part_no
where 1=1
and ISNULL(sbm.promo_id,'')  IN ('pc','ff','style out') 
AND RIGHT(sbm.user_category,2) <> 'rb'
-- AND sbm.return_code <> 'exc'
-- and sbm.DateOrdered between DATEADD(dd,1,#t.first_order_date) and @dateto
and sbm.yyyymmdd between @datefrom and @dateto
GROUP BY 
#t.customer_code, #t.type_code

INSERT INTO #v
SELECT 
 #t.customer_code
,#t.type_code
, sum(ISNULL(qnet,0)) units
, 'ST' sale_type
FROM
 #t
inner join inv_master i on i.category=#t.brand AND i.type_code = #t.type_code
inner join inv_master_add ia on ia.part_no = i.part_no
inner join #attrib a on a.attrib = ISNULL(ia.field_32,'')
INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code AND sbm.part_no = i.part_no
where 1=1
and ISNULL(sbm.promo_id,'') NOT IN ('pc','ff','style out') 
AND LEFT(sbm.user_category,2) IN ('ST','') AND RIGHT(sbm.user_category,2) <> 'rb'
-- AND sbm.return_code <> 'exc'
and sbm.yyyymmdd between DATEADD(dd,1,#t.first_order_ship) and @dateto
GROUP BY 
#t.customer_code, #t.type_code

IF @debug =1 SELECT * FROM #v WHERE customer_code = '026595'

IF(OBJECT_ID('tempdb.dbo.#newrea') is not null)  drop table #newrea

create table #newrea
( newrea varchar(3),
 customer_code varchar(10), 
 ship_to_code VARCHAR(8),
 firstst_new datetime,
 prevst_new datetime
 )

declare @cust varchar(10)

select @cust = min(customer_code) from #t

IF @debug = 1 SELECT * FROM #t WHERE customer_code = @cust

while @cust is not null
begin
	-- get new/reactivated status
	insert into #newrea exec cvo_newreacust_sp @cust
	  
	select @cust = min(customer_code) From #t where customer_code > @cust
end


IF EXISTS (SELECT 1 fp FROM #fp) -- @promo_id IS NOT NULL AND @promo_level IS NOT NULL
begin
	UPDATE #t SET highlight_ship_date = s.h_date
	FROM 
	#t 
	INNER JOIN
	(SELECT customer, MIN(yyyymmdd) h_date
	FROM  dbo.cvo_sbm_details  sbm
	INNER JOIN #fp ON #fp.fp = sbm.promo_id
	INNER JOIN #fl ON #fl.fl = sbm.promo_level

	WHERE 1=1 
	-- promo_id = @promo_id AND promo_level = @promo_level
		 and sbm.yyyymmdd between @datefrom and @dateto
		 and user_category like 'ST%' and right(user_category,2) <> 'rb'
		 -- AND sbm.return_code <> 'exc'
	GROUP BY customer 
	) AS s ON #t.customer_code = s.customer 
end

select DISTINCT #t.territory_code ,
                #t.customer_code ,
                #t.customer_name ,
				#t.contact_name,
				#t.contact_phone,
				#t.contact_email,
                #t.promo_id ,
				#t.promo_level,
                #t.brand ,
                #t.type_code ,
                #t.attrib ,
                #t.first_order_date ,
                #t.first_order_ship ,
                #t.highlight_ship_date,
				#v.units ,
                #v.sale_type
, isnull(#newrea.newrea,'') newrea
, c.description brand_name
, dbo.calculate_region_fn(#t.territory_code) region
 From  #t 
 left outer join #newrea on #t.customer_code = #newrea.customer_code 
  INNER join category c on c.kys = #t.brand
  LEFT OUTER JOIN #v ON #v.customer_code = #t.customer_code AND #v.type_code = #t.type_code
 WHERE 1=1
order by customer_code



GO
