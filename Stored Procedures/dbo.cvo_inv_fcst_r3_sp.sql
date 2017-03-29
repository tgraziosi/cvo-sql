SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_inv_fcst_r3_sp] 

-- re-write for y1 figures not pulling enough history to properly generate
-- 3/21/2017 - pull out the ranking features; clean up; multi-location reporting; RA %

@asofdate datetime, 
@location VARCHAR(1000),
@endrel DATETIME = null, -- ending release date
@current int = 1,
@collection varchar(1000) = null,
@Style varchar(8000) = NULL,
@SpecFit varchar(1000) = NULL,
@gender VARCHAR(1000) = NULL,
@ResType VARCHAR(1000) = NULL,
@usg_option CHAR(1) = 'O'
, @Season_start int = NULL
, @Season_end int = NULL
, @Season_mult DECIMAL (20,8) = NULL
, @spread VARCHAR(10) = null
, @debug INT = 0
--
/*
 exec cvo_inv_fcst_r3_sp

 @asofdate = '03/01/2017', 
 @endrel = '03/01/2017', 
 @current = 1, 
 @collection = 'cvo', 
 @style = 'adam ii', 
 @specfit = '*all*',
 @usg_option = 'o',
 @debug = 1, -- debug
 @location = '001',
 @restype = 'frame,sun'

 select * From cvo_ifp_rank

*/
-- 090314 - tag
-- get sales since the asof date, and use it to consume the demand line
-- 10/29/2014 - ADD additional info to match DRP
-- 1/9/2015 - update sales PCT for demand multipliers per BL schedule
-- 2/11/2015 - fix po line not picking up po's for suns

-- @current - 0 = show all, 1 = current only (no POMs)
-- 12/3/14 - tag - fix pom styles/skus
-- 6/17/15 - fix sku's doubling up because of release dates
-- 7/20/15 - add avail to promise and option to select by Specialty Fit attribute
-- 7/22/15 - add usage option for orders or shipments
-- 07/29/2015 - dont include credit hold orders
-- 8/18/2015 - fix po qty when there are multiple po's in the same month
-- 9/3/2015 - fix for  po lines in next year
-- 10/6/2015 - PO lines - make the outer range < not <= to avoid 13th bucket on report
-- 10/20/2015 - add seasonality multiplier, promo and substitute flagging
-- 07/15/2016 - calc starting inventory with allocations if usage is on orders, and without if usage is on shipments.
-- 12/2016 - misc updates to add additional info like pricing shape materials
	
as 
begin

set nocount ON
SET ANSI_WARNINGS OFF


declare @startdate datetime, @enddate datetime, @pomdate datetime
/* for testing

--, @asofdate datetime
--, @current int
*/

set @pomdate = @asofdate
set @startdate = '01/01/1949'  -- starting release date
-- set @enddate = '12/31/2020' -- ending release date
-- set @enddate = @asofdate
set @enddate = ISNULL(@endrel, @asofdate)



declare @coll_list varchar(1000), @style_list varchar(8000), @sf VARCHAR(1000), @gndr VARCHAR(1000), @type_code VARCHAR(1000),
		@s_start INT, @s_end INT, @s_mult DECIMAL(20,8), @sku VARCHAR(40), @loc VARCHAR(1000)

select @coll_list = @collection, @style_list = @style, @SF = @SpecFit, @gndr = @gender, @type_code = @ResType
	 , @s_start = ISNULL(@Season_start,1), @s_end = ISNULL(@Season_end,12), @S_mult = ISNULL(@Season_mult,1), @loc = @location

-- select @style_list

CREATE TABLE #coll ([coll] VARCHAR(20))
if @coll_list is null
begin
	insert into #coll
	select distinct kys from category where void = 'n'
end
else
begin
	INSERT INTO #coll ([coll])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@coll_list)
end

CREATE TABLE #style_list ([style] VARCHAR(40))
if @style_list is NULL OR @style_list LIKE '%*ALL*%'
begin
	insert into #style_list
	select distinct field_2  from inv_master_add ia (nolock) 
		inner join	inv_master i (nolock) on i.part_no = ia.part_no  
		inner join #coll on #coll.coll = i.category
		where i.void = 'n' 
end
else
begin
	INSERT INTO #style_list ([style])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@style_list)
end

CREATE TABLE #sf ([sf] VARCHAR(20))
if @sf is NULL OR @sf LIKE '%*ALL*%'
BEGIN
	INSERT INTO #sf (sf) VALUES('')
	insert into #sf (sf)
	select distinct kys from cvo_specialty_fit where void = 'n'
end
else
begin
	INSERT INTO #sf ([sf])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@sf)
END

CREATE TABLE #loc ([location] VARCHAR(10))
if @loc is NULL OR @loc LIKE '%*ALL*%'
BEGIN
	insert into #loc (location)
	select DISTINCT la.[location] from dbo.locations_all AS la WHERE la.void = 'n'
end
else
begin
	INSERT INTO #loc ([location])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@loc)
END

-- get gender selections

CREATE TABLE #gender ([gender] VARCHAR(20))
if @gndr is NULL OR @gndr LIKE '%*ALL*%'
BEGIN
	INSERT INTO #gender (gender) VALUES('')
	insert into #gender (gender)
	select distinct kys from dbo.CVO_Gender  where void = 'n'
end
else
begin
	INSERT INTO #gender ([gender])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@gndr)
END

CREATE TABLE #type (type_code VARCHAR(10))
if @type_code is null
begin
	insert into #type
	select distinct type_code from dbo.inv_master AS i
end
else
begin
	INSERT INTO #type (type_code)
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@type_code)
END

--select * from #style_list
--select @style_list

--IF ISNULL(@debug,0) = 1
--BEGIN
--	SELECT @specfit
--	SELECT * FROM #sf
--end

--declare @loc varchar(10)
----select @loc = '001'
--SELECT @loc = @location

IF(OBJECT_ID('tempdb.dbo.#dmd_mult') is not null)  drop table #dmd_mult
create table #dmd_mult
(mm int,
pct_sales decimal(20,8),
mult decimal(20,8),
s_mult DECIMAL(20,8),
sort_seq int
)


-- 8/17/2016
SET @SPREAD = ISNULL(@SPREAD,'CORE')

insert into #dmd_mult
select mm, pct_sales, 0 , 0, 0 
FROM cvo_dmd_mult
where obs_date is NULL 
AND asofdate = (SELECT MAX(asofdate) 
				FROM cvo_dmd_mult WHERE asofdate <= GETDATE() AND SPREAD = @SPREAD)
-- alternate spread %'s
AND spread = @spread

-- select sum(pct_sales) from #dmd_mult -- 1.0001 for 2015
-- 0.99980000 for 2/2015

update #dmd_mult set sort_seq = 
CASE when mm < month(@asofdate) then mm - MONTH(@ASOFDATE) + 13
	 ELSE mm - MONTH(@ASOFDATE) + 1 END 

declare @sort_seq int, @base_pct FLOAT, @flatten decimal(20,8)

	set @base_pct = (select avg(pct_sales) from #dmd_mult where sort_seq in (10,11,12)/*(11,12,1)*/ ) -- last 3 months sales %
	-- the multiplier s/b the average of the 3 months prior to the asofdate

	set @sort_seq = 1
	while @sort_seq <= 12
	begin
 	 UPDATE #dmd_mult set mult = round(1+((pct_sales-@base_pct)/@base_pct),4)
		 , s_mult = CASE WHEN @sort_seq BETWEEN @s_start AND @s_end THEN @s_mult ELSE 1.0 end
		 where sort_seq = @sort_seq

	 set @sort_seq = @sort_seq + 1
	end


	select @flatten = sum(mult) from #dmd_mult
	update #dmd_mult set mult = mult * (12/@flatten)
--END

-- select * From #dmd_mult

IF(OBJECT_ID('tempdb.dbo.#sls_det') is not null)  drop table #sls_det
IF(OBJECT_ID('tempdb.dbo.#cte') is not null)  drop table #cte
IF(OBJECT_ID('tempdb.dbo.#style') is not null)  drop table #style
IF(OBJECT_ID('tempdb.dbo.#tmp') is not null)  drop table #tmp
IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t
IF(OBJECT_ID('tempdb.dbo.#SKU') is not null)  drop table #SKU
IF(OBJECT_ID('tempdb.dbo.#usage') is not null)  drop table #usage

CREATE TABLE #sku
    (
      LINE_TYPE VARCHAR(3) ,
      sku VARCHAR(30) ,
      location VARCHAR(12) ,
      mm INT ,
      bucket DATETIME ,
      QOH INT ,
      atp INT ,
      reserve_qty INT ,
      quantity INT ,
      mult DECIMAL(20, 8) ,
      s_mult DECIMAL(20, 8) ,
      sort_seq INT
    );


-- get weekly usage

CREATE TABLE #usage 
( location VARCHAR(12), part_no VARCHAR(40)
, usg_option CHAR(1), asofdate datetime
, e4_wu INT, e12_wu INT, e26_wu INT, e52_wu INT
, subs_w4 INT, subs_w12 INT, promo_w4 INT, promo_w12 INT
, rx_w4 INT, rx_w12 INT -- 12/5/2016
, ret_w4 int, ret_w12 int
, wty_w4 int, wty_w12 INT
, gross_w4 INT, gross_w12 int
)

-- 10/24/2016 - switch over to usage by collection for performance

DECLARE @co VARCHAR(20)
SELECT @co = MIN(coll) FROM #coll AS c
WHILE @co IS NOT NULL
BEGIN
	INSERT INTO #usage 
	(location, part_no, usg_option, asofdate, e4_wu, e12_wu, e26_wu, e52_wu, subs_w4, subs_w12, promo_w4, promo_w12, rx_w4, rx_w12,
	ret_w4, ret_w12, wty_w4, wty_w12, gross_w4, gross_w12)
	select location, part_no, usg_option, asofdate, e4_wu, e12_wu, e26_wu, e52_wu, subs_w4, subs_w12, promo_w4, promo_w12, rx_w4, rx_w12,
	ret_w4, ret_w12, wty_w4, wty_w12, gross_w4, gross_w12
	from dbo.f_cvo_calc_weekly_usage_COLL (@usg_option, @CO)
	SELECT @CO = MIN(COLL) FROM #COLL WHERE COLL > @co
END

-- get sales history
select
i.category brand,
ia.field_2 style,
s.location,
i.part_no,
i.type_code,
isnull(ia.field_28,'1/1/1900') pom_date,
ia.field_26 rel_date,
datediff(m,ia.field_26, isnull(s.yyyymmdd,@asofdate)) as rel_month, 
sum(case when isnull(s.yyyymmdd,@asofdate) < dateadd(mm,12,ia.field_26)
		 then isnull(qsales,0)- isnull(qreturns,0) else 0 end) yr1_net_qty,
sum(case when isnull(s.yyyymmdd,@asofdate) < @asofdate 
		and datediff(m,ia.field_26,isnull(s.yyyymmdd,@asofdate)) <= 12 
		then isnull(qsales,0) - isnull(qreturns,0) else 0 end) yr1_net_qty_b4_asof,
sum(case when isnull(s.yyyymmdd,@asofdate) < @asofdate 
		and datediff(m,ia.field_26,isnull(s.yyyymmdd,@asofdate)) BETWEEN 12 AND 24 
		then isnull(qsales,0) - isnull(qreturns,0) else 0 end) yr2_net_qty_b4_asof,
sum(isnull(qsales,0)) as sales_qty,
sum(isnull(qreturns,0)) as ret_qty

into #sls_det

from inv_master i (nolock)
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
inner join #coll on #coll.coll = i.category
inner join #style_list on #style_list.style = ia.field_2
INNER JOIN #type t ON t.type_code = i.type_code
LEFT outer join cvo_sbm_details s (nolock) on s.part_no = i.part_no
left outer join armaster a (nolock) on a.customer_code = s.customer and a.ship_to_code = s.ship_to
where 
1=1
and ia.field_26 >= @startdate
and i.void = 'N'
AND EXISTS (SELECT 1 FROM #sf WHERE #sf.sf = ISNULL(ia.field_32,''))
AND EXISTS (SELECT 1 FROM #gender WHERE #gender.gender = ISNULL(ia.category_2,''))
AND EXISTS (select 1  FROM #loc WHERE #loc.location = ISNULL(s.location,'001'))

and isnull(s.customer,'') not in ('045733','019482','045217') -- stanton and insight and costco
and isnull(s.return_code,'') = ''
and isnull(s.iscl,0) = 0 -- no closeouts
and isnull(s.location,@loc) = @loc

group by ia.field_26, ia.field_28, i.category, ia.field_2, i.part_no, i.type_code, s.location, s.yyyymmdd -- end cte

select 
#sls_det.brand,
#sls_det.style,
max(type_code) type_code,
ISNULL(tt.style_pom,MIN(#sls_det.pom_date)) pom_date,
min(rel_date) rel_date,
rel_month, 
sum (yr1_net_qty) yr1_net_qty,
sum (yr1_net_qty_b4_asof) yr1_net_qty_b4_asof,
sum (yr2_net_qty_b4_asof) yr2_net_qty_b4_asof,
sum (sales_qty) as sales_qty,
sum (ret_qty) as ret_qty
into #cte
from #sls_det 
LEFT OUTER JOIN 
(SELECT t.Collection brand, t.model style, MAX(t.pom_date) style_pom
FROM dbo.cvo_inv_master_r2_vw t
JOIN #sls_det ON #sls_det.brand = t.COLLECTION AND #sls_det.style = t.MODEL
GROUP BY	t.Collection , t.model
HAVING COUNT(t.part_no) = COUNT(t.pom_date) -- fully pom'd style
) AS tt ON tt.brand = #sls_det.brand AND tt.style = #sls_det.style
group BY #sls_det.brand, #sls_det.style, #sls_det.rel_month, tt.style_pom

IF @debug = 1 SELECT ' cte ', * From #cte -- where style = '185' order by style, rel_month

-- Create style summary list

 select cte.brand, cte.style , '' as part_no
 ,min(cte.pom_date) pom_date
 ,min(cte.rel_date) rel_date
 ,max(rel_month) mth_since_rel
,sum(case when rel_month <=3 then sales_qty else 0 end) [Sales M1-3] 
,sum(case when rel_month <=12 then sales_qty else 0 end) [Sales M1-12]
, ISNULL(drp.s_e4_wu,0) s_e4_wu 
, ISNULL(drp.s_e12_wu,0) s_e12_wu 
, ISNULL(drp.s_e52_wu,0) s_e52_wu
, ISNULL(drp.s_promo_w4,0) s_promo_w4
, ISNULL(drp.s_promo_w12,0) s_promo_w12
, ISNULL(drp.s_rx_w4,0) s_rx_w4
, ISNULL(drp.s_rx_w12,0) s_rx_w12
, ISNULL(drp.s_ret_w4,0) s_ret_w4
, ISNULL(drp.s_ret_w12,0) s_ret_w12
, ISNULL(drp.s_wty_w4,0) s_wty_w4
, ISNULL(drp.s_wty_w12,0) s_wty_w12
, ISNULL(drp.s_gross_w4,0) s_gross_w4
, ISNULL(drp.s_gross_w12,0) s_gross_w12

 
into #style -- tally up style level information
from #cte cte


left outer join
(select -- usage info
i.category collection,
ia.field_2 style, 
sum(ISNULL(e4_wu,0)) s_e4_wu, sum(ISNULL(e12_wu,0)) s_e12_wu, sum(ISNULL(e52_wu,0)) s_e52_wu
, SUM(ISNULL(promo_w4,0)) s_promo_w4, SUM(ISNULL(promo_w12,0)) s_promo_w12
, SUM(ISNULL(rx_w4,0)) s_rx_w4, SUM(ISNULL(rx_w12,0)) s_rx_w12
, SUM(ISNULL(ret_w4,0)) s_ret_w4, SUM(ISNULL(ret_w12,0)) s_ret_w12
, SUM(ISNULL(wty_w4,0)) s_wty_w4, SUM(ISNULL(wty_w12,0)) s_wty_w12
, SUM(ISNULL(gross_w4,0)) s_gross_w4, SUM(ISNULL(gross_w12,0)) s_gross_w12
from inv_master i (NOLOCK)
LEFT OUTER JOIN #usage drp (nolock) ON i.part_no = drp.part_no
INNER JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no
where i.void = 'N' 
AND EXISTS (SELECT 1 FROM #loc WHERE #loc.location = drp.location)
group by i.category, ia.field_2
) as drp
on drp.collection = cte.brand and drp.style = cte.style 

group by cte.brand, cte.style, drp.s_e4_wu, drp.s_e12_wu, drp.s_e52_wu, drp.s_promo_w4, drp.s_promo_w12, drp.s_rx_w4, drp.s_rx_w12
, drp.s_ret_w4, drp.s_ret_w12
, drp.s_wty_w4, drp.s_wty_w12
, drp.s_gross_w4, drp.s_gross_w12
order by cte.brand, cte.style

-- select * from #style where style = '185'

-- Check for current styles

IF @debug = 1 SELECT * FROM #style

-- select * From #style where style = 'clarissa'

-- summarize further and start adding part level information

select s.brand
, s.style
, drp.location
, i.part_no
, s.rel_date
, s.pom_date
, s.mth_since_rel
, isnull(s.s_e4_wu,0) s_e4_wu
, isnull(s.s_e12_wu,0) s_e12_wu
, isnull(s.s_e52_wu,0) s_e52_wu
, isnull(s.s_promo_w4,0) s_promo_w4
, ISNULL(s.s_promo_w12,0) s_promo_w12
, isnull(s.s_rx_w4,0) s_rx_w4
, ISNULL(s.s_rx_w12,0) s_rx_w12
, isnull(s.s_ret_w4,0) s_ret_w4
, ISNULL(s.s_ret_w12,0) s_ret_w12
, isnull(s.s_wty_w4,0) s_wty_w4
, ISNULL(s.s_wty_w12,0) s_wty_w12
, isnull(s.s_gross_w4,0) s_gross_w4
, ISNULL(s.s_gross_w12,0) s_gross_w12

, isnull(drp.p_e4_wu,0) p_e4_wu
, isnull(drp.p_e12_wu,0) p_e12_wu
, isnull(drp.p_e52_wu,0) p_e52_wu
, ISNULL(drp.p_subs_w4,0) p_subs_w4
, ISNULL(drp.p_subs_w12,0) p_subs_w12
, ISNULL(drp.p_rx_w4,0) p_rx_w4
, ISNULL(drp.p_rx_w12,0) p_rx_w12
, ISNULL(drp.p_ret_w4,0) p_ret_w4
, ISNULL(drp.p_ret_w12,0) p_ret_w12
, ISNULL(drp.p_wty_w4,0) p_wty_w4
, ISNULL(drp.p_wty_w12,0) p_wty_w12
, ISNULL(drp.p_gross_w4,0) p_gross_w4
, ISNULL(drp.p_gross_w12,0) p_gross_w12

, s_mth_usg = round(( case when mth_since_rel <= 3 then isnull(s_e4_wu,0)*52/12
	else isnull(s_e12_wu,0)*52/12 end ) ,0,1)
, p_mth_usg = round((case when mth_since_rel <= 3 then isnull(p_e4_wu,0)*52/12
	else isnull(p_e12_wu,0)*52/12 end ) ,0,1)
, s_mth_usg_mult = round((( case when mth_since_rel <= 3 then isnull(s_e4_wu,0)*52/12
	else isnull(s_e12_wu,0)*52/12 end ) * mult) ,0,1)
, p_mth_usg_mult = round(((case when mth_since_rel <= 3 then isnull(p_e4_wu,0)*52/12
	else isnull(p_e12_wu,0)*52/12 end ) * mult) ,0,1) 
, pct_of_style = round((case when isnull(CAST(s_e12_wu AS DECIMAL),0.00) <> 0.00	
							 then isnull(CAST(p_e12_wu AS DECIMAL),0.00)/isnull(CAST(s_e12_wu AS DECIMAL),0) else 0.00 end),4)
, first_po = isnull((select top 1 quantity From releases 
	where part_no = i.part_no and location = drp.location and part_type = 'p' and status = 'c' 
	order by release_date),0)
, pct_first_po = cast (0 as float) -- calculate this later
, p_sales_m1_3 = 0
, pct_sales_style_m1_3 = cast(0 as float)
, mm, mult, s_mult, sort_seq -- stuff from #dmd_mult
, mth_demand_src = 'xxx' 
, mth_demand_mult = null
, p_po_qty_y1 = cast (0 as float)

into #t

From inv_master i (nolock)
JOIN #type t ON t.type_code = i.type_code
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
inner join #style s on s.brand = i.category and s.style = ia.field_2
-- and ia.field_26 between @startdate and @enddate
and ia.field_26 >= @startdate
left outer join
(select -- drp info by part
drp.location, drp.part_no, sum(ISNULL(e4_wu,0)) p_e4_wu, sum(ISNULL(e12_wu,0)) p_e12_wu, sum(ISNULL(e52_wu,0)) p_e52_wu
, SUM(ISNULL(drp.subs_w4,0)) p_subs_w4, SUM(ISNULL(drp.subs_w12,0)) p_subs_w12
, SUM(ISNULL(drp.rx_w4,0)) p_rx_w4, SUM(ISNULL(drp.rx_w12,0)) p_rx_w12
, SUM(ISNULL(drp.ret_w4,0)) p_ret_w4, SUM(ISNULL(drp.ret_w12,0)) p_ret_w12
, SUM(ISNULL(drp.wty_w4,0)) p_wty_w4, SUM(ISNULL(drp.wty_w12,0)) p_wty_w12
, SUM(ISNULL(drp.gross_w4,0)) p_gross_w4, SUM(ISNULL(drp.gross_w12,0)) p_gross_w12


from #usage drp (nolock)
JOIN inv_master i ON i.part_no = drp.part_no
JOIN #type t ON t.type_code = i.type_code
where EXISTS (SELECT 1 FROM #loc WHERE location = drp.location)
group by drp.location, drp.part_no 
) as drp
on drp.part_no = i.part_no

cross join #dmd_mult
-- where i.type_code in ('FRAME','sun','BRUIT','PARTS') -- 11/1/16 - ADD PARTS
WHERE 1=1
  and i.void = 'n'

create index idx_t on #t (part_no asc)

IF ISNULL(@debug,0) = 1
BEGIN
 SELECT * FROM #dmd_mult
 SELECT * FROM #t

 SELECT brand, style, COUNT(DISTINCT rel_date) rel_date_cnt
FROM #t 
GROUP BY brand, style
HAVING COUNT(DISTINCT rel_date) = 1
AND MAX(rel_date) > @endrel
-- ) future_releases

END 

if @current = 1  -- if reporting current styles/skus only remove any pom skus 
begin
	delete from #t where exists (select 1 from inv_master_add where part_no = #t.part_no and field_28 is not null and field_28 < @asofdate )
END

-- remove any skus after the ending release date (full styles only)


DELETE FROM #t 
	WHERE EXISTS (SELECT 1 FROM 
	(SELECT brand, style, COUNT(DISTINCT rel_date) rel_date_cnt
	FROM #t 
	GROUP BY brand, style
	HAVING COUNT(DISTINCT rel_date) = 1
	AND MAX(rel_date) > @endrel
	) future_releases
	WHERE #t.brand = future_releases.brand AND #t.style = future_releases.style
	)

IF @debug = 1  SELECT 'after future_releases removed', * FROM #t AS t

-- figure out pct of first purchase
;with x as 
(select distinct 
SKU.brand, sku.style, sku.part_no, sku.first_po, 
style_first_po = (select sum(isnull(t.first_po,0)) 
	from (select distinct #T.part_no, first_po 
		FROM #t 
		  JOIN inv_master i ON i.part_no = #t.part_no
		  where #t.style = sku.style 
		  AND #t.brand = sku.brand
		  AND i.type_code IN ('frame','sun','bruit')
		  ) as t
		  )
from #t sku
JOIN inv_master ii ON ii.part_no = sku.part_no
-- WHERE i.type_code IN ('frame','sun','bruit')
)
update #t set 
pct_first_po = 
	round((case when isnull(x.style_first_po,0.00) = 0.00 then 0.00
	      else cast(isnull(x.first_po,0.00)/isnull(x.style_first_po,1) as float) end),4)
from #t inner join x on #t.part_no = x.part_no
where isnull(x.style_first_po,0.00) <> 0.00;
-- where #t.style = 'clarissa'

-- figure out first 3 months sales by part

;with x as 
(
select s.part_no, sum(s.sales_qty) p_sales_m1_3
from #sls_det s
where s.rel_month <=3
group by part_no
--order by part_no
)
update #t set #t.p_sales_m1_3 = x.p_sales_m1_3
, #t.pct_sales_style_m1_3 = round(x.p_sales_m1_3 /isnull(s.[sales m1-3],1),4)
from #t 
inner join x on #t.part_no = x.part_no
inner join #style s on s.brand = #t.brand and s.style = #t.style
where isnull(s.[sales m1-3],0) <> 0
-- select * From #t

insert into #sku
select distinct mth_demand_src AS LINE_TYPE, 
#t.part_no sku,
#t.location,
#t.mm,
bucket = dateadd(m,#t.sort_seq-1, @asofdate),
QOH = 0,
atp = 0,
reserve_qty = 0,
ROUND(#t.mth_demand_mult,0,1) as quantity,
#t.mult,
#t.s_mult,
#t.sort_seq
-- into #SKU
from #t
where mth_demand_src <> 'xxx'

-- order by #t.part_no, sort_seq

-- add DRP data too


select 'DRP' AS LINE_TYPE, 

#t.part_no sku,
#t.location,
#t.mm,
bucket = dateadd(m,#t.sort_seq-1, @asofdate),
QOH = 0,
atp = 0, 
reserve_qty = 0,
quantity = round(#dmd_mult.mult * #dmd_mult.s_mult * (case when datediff(mm,ia.field_26, @asofdate) > 3 then isnull(p_e12_wu,0)*52/12 else isnull(p_e4_wu,0)*52/12 end),0,1),
#t.mult,
#t.s_mult,
#t.sort_seq

from #t 
inner join #dmd_mult on #t.sort_seq = #dmd_mult.sort_seq
inner join inv_master_add ia on ia.part_no = #t.part_no

-- order by #t.part_no, sort_seq


-- GET PURCHASE ORDER LINES MAPPED OUT BY MONTH UNTIL THE ENDING DATE
insert into #SKU
select -- 
'PO' as line_type

,#t.part_no sku
, #t.location
,#t.mm
, bucket = dateadd(m,#t.sort_seq-1, @asofdate)
,QOH = 0
,atp = 0
,reserve_qty = 0
,round(SUM(ISNULL(R.quantity,0))-SUM(ISNULL(R.received,0)),1) quantity, 
#t.mult,
#t.s_mult,
#t.sort_seq
From #t 
inner join inv_master_add i (nolock) on i.part_no = #t.part_no
inner join inv_master inv (nolock) on inv.part_no = i.part_no
inner join #type t on t.type_code = inv.type_code
left outer join releases r (nolock) on #t.part_no = r.part_no 
where 1=1
AND EXISTS (SELECT 1 FROM #loc WHERE #loc.location = r.location)
and  #t.mm = case when DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0) < @asofdate
	 THEN month(@asofdate) 
	 ELSE month(DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)) end
and r.status = 'o' and r.part_type = 'p' -- and r.location = @loc
and inv.void = 'N'
AND DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0) < DATEADD(YEAR,1,@asofdate)
group BY inv.category, i.field_2, #t.part_no, #t.location, DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)
	, MONTH(r.inhouse_date), #t.mm, #t.mult, #t.s_mult, #t.sort_seq

IF @debug = 1 select * From #SKU  WHERE LINE_TYPE = 'po' ORDER by sku, sort_seq

-- select * From #t

-- 090314 - tag
-- get sales since the asof date, and use it to consume the demand line

insert into #SKU
select -- 
'SLS' as line_type

,#t.part_no sku
,#t.location
, ISNULL(r.x_month,MONTH(@asofdate)) mm
, bucket = dateadd(m,#t.sort_seq-1, @asofdate)
, QOH = 0
, atp = 0
, reserve_qty = 0
,round(sum(isnull(R.qsales,0)-ISNULL(r.qreturns,0)),0,1) quantity, 
#t.mult,
#t.s_mult,
CASE when ISNULL(r.x_month,month(@asofdate)) < month(@asofdate) 
		 then ISNULL(r.x_month,month(@asofdate)) - MONTH(@ASOFDATE) + 13
		 ELSE ISNULL(r.x_month,MONTH(@asofdate)) - MONTH(@ASOFDATE) + 1 
		 END  as sort_seq
From #t 
inner join inv_master_add i (nolock) on i.part_no = #t.part_no
inner join inv_master inv (nolock) on inv.part_no = i.part_no
left outer join cvo_sbm_details r (nolock) on #t.part_no = r.part_no
where r.yyyymmdd >= @asofdate 
AND EXISTS (SELECT 1 FROM #loc WHERE location = r.location)
-- and @pomdate 
and r.x_month = #t.mm
and inv.void = 'N'
group by inv.category, i.field_2, #t.part_no, #t.location, r.x_month, #t.mult, #t.s_mult, #t.sort_seq
-- select * From #SKU  order by sku, sort_seq
-- select * From #t

-- 06/17/2015 - add orders line

insert into #SKU
select -- 
'ORD' as line_type

,#t.part_no sku
,#t.location
,rr.x_month mm
,bucket = dateadd(m,#t.sort_seq-1, @asofdate)
,QOH = 0
, atp = 0
, reserve_qty = 0
,round(sum(isnull(Rr.open_qty,0)),0,1) quantity, 
#t.mult,
#t.s_mult,
CASE when rr.x_month < month(@asofdate) 
		 then rr.x_month - MONTH(@ASOFDATE) + 13
		 ELSE rr.x_month - MONTH(@ASOFDATE) + 1 
		 END  as sort_seq
From #t 
inner join inv_master_add i (nolock) on i.part_no = #t.part_no
inner join inv_master inv (nolock) on inv.part_no = i.part_no
LEFT OUTER JOIN
(SELECT  ol.part_no ,
        X_MONTH = CASE when o.sch_ship_date < @asofdate THEN MONTH(@asofdate) ELSE MONTH(o.sch_ship_date) end,
        YYYYMMDD = CASE WHEN o.sch_ship_date < @asofdate THEN @asofdate ELSE o.sch_ship_date end ,
        open_qty = SUM(ol.ordered - ol.shipped - ISNULL(ha.qty, 0))
		FROM    orders o ( NOLOCK )
        INNER JOIN ord_list ol ( NOLOCK ) ON ol.order_no = o.order_no
                                             AND ol.order_ext = o.ext
        LEFT OUTER JOIN dbo.cvo_hard_allocated_vw ha ( NOLOCK ) ON ha.line_no = ol.line_no
                                                              AND ha.order_ext = ol.order_ext
                                                              AND ha.order_no = ol.order_no
        LEFT OUTER JOIN cvo_soft_alloc_det sa ( NOLOCK ) ON sa.order_no = ol.order_no
                                                            AND sa.order_ext = ol.order_ext
                                                            AND sa.line_no = ol.line_no
                                                            AND sa.part_no = ol.part_no
WHERE   o.status < 'r'
		AND o.status <> 'c'  -- 07/29/2015 - dont include credit hold orders
        AND o.type = 'i'
        AND ol.ordered > ol.shipped + ISNULL(ha.qty, 0)
        AND ISNULL(sa.status, -3) = -3 -- future orders not yet soft allocated
        AND ol.part_type = 'P'
		AND EXISTS (SELECT 1 FROM #loc WHERE location = ol.location)
GROUP BY ol.part_no ,
		 ol.location,
        MONTH(o.sch_ship_date) ,
        o.sch_ship_date
) rr on #t.part_no = rr.part_no
where rr.yyyymmdd >= @asofdate 
-- and @pomdate 
and rr.x_month = #t.mm
-- and inv.type_code in ('FRAME','sun','BRUIT','PARTS') -- 11/1/16 - ADD PARTS
-- and r.status = 'o' and r.part_type = 'p' and r.location = @loc
and inv.void = 'N'
group by inv.category, i.field_2, #t.part_no, #t.location, rr.x_month, #t.mult, #t.s_mult, #t.sort_seq
-- select * From #SKU  order by sku, sort_seq
-- select * From #t




-- figure out the running total inv available line
-- 11/19/14 - Change INV line calculation to consume the demand line using the greater of fct/drp or sls as the demand line
-- 7/20/15 - add avail to promise

declare @inv int, @last_inv int, @INV_AVL INT, @drp int, @sls int, @po INT, @ord INT, @atp INT, @reserve_inv int

create index idx_f on #SKU (sku asc)

create index idx_sku_line_sort ON #SKU (sku ASC, LINE_TYPE ASC, sort_seq asc)

select @sku = min(sku) from #SKU
-- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
	SELECT @last_inv = isnull(cia.in_stock,0) + isnull(cia.qcqty2,0) - 
		   CASE WHEN @usg_option = 'O' THEN 0 else isnull(cia.sof,0) + isnull(cia.allocated,0) end 
		   , @atp = ISNULL(qty_avl,0)
		   , @reserve_inv = ISNULL(cia.ReserveQty,0) -- 12/5/2016
	from cvo_item_avail_vw cia 	WHERE  cia.part_no = @sku and EXISTS (SELECT 1 FROM #loc WHERE location = cia.location)



select @sort_seq = 0
SELECT @INV_AVL = @LAST_INV
select @drp = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'drp' and sort_seq = @sort_seq+ 1
select @sls = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'sls' and sort_seq = @sort_seq+ 1
select @po = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'po' and sort_seq = @sort_seq+ 1
select @ord = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'ord' and sort_seq = @sort_seq+ 1

-- select * From cvo_item_avail_vw where part_no = 'etkatbur5018' and location = '001'


while @sku is not null 
BEGIN

	--IF @debug = 1 
	--	BEGIN
	--	 SELECT @sku, @last_inv, @atp, @reserve_inv
	--	 SELECT * FROM dbo.cvo_item_avail_vw AS iav WHERE iav.part_no = @sku AND iav.location = @loc
	--	END
        

	update #SKU set qoh = isnull(@last_inv,0)
					, atp = ISNULL(@atp,0)
					, reserve_qty = ISNULL(@reserve_inv,0)
					  where sku = @sku

	WHILE @SORT_SEQ < 12
	BEGIN
		SELECT @INV_AVL = @INV_AVL 
		- case when @drp < @sls then @sls else @drp end
		-- add back sales after the as of date (consume the demand line)
		+ isnull(@sls, 0)
		+ isnull(@po, 0)
		- ISNULL(@ord, 0)

		insert #sku
		select 
		'V' AS line_type
		,sku = @sku
		,#t.location
		,mm= #t.mm
		,bucket = DATEADD(m, @sort_seq, @asofdate)
		,QOH = isnull(@LAST_INV,0)
		, atp = ISNULL(@atp,0)
		, reserve_qty = ISNULL(@reserve_inv,0)
		,QUANTITY = isnull(@INV_AVL ,0)
		,mult = #t.mult
		, s_mult = #t.s_mult
		,SORT_SEQ = #T.SORT_SEQ
		FROM #T WHERE #T.PART_NO = @SKU AND SORT_SEQ = @SORT_SEQ + 1

		SELECT @SORT_SEQ = @SORT_SEQ + 1
		select @drp = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'drp' and sort_seq = @sort_seq + 1
		select @sls = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'sls' and sort_seq = @sort_seq + 1
		select @po = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'po' and sort_seq = @sort_seq + 1
		select @ord = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'ord' and sort_seq = @sort_seq + 1
	END
	SELECT @SKU = MIN(SKU) FROM #SKU WHERE SKU > @SKU
-- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
	SELECT @last_inv = isnull(cia.in_stock,0) + isnull(cia.qcqty2,0) - 
		   CASE WHEN @usg_option = 'O' THEN 0 else isnull(cia.sof,0) + isnull(cia.allocated,0) end 
		   , @atp = ISNULL(qty_avl,0)
		   , @reserve_inv = ISNULL(cia.ReserveQty,0)
	from cvo_item_avail_vw cia 	WHERE  cia.part_no = @sku 
		AND EXISTS (SELECT 1 FROM #loc WHERE #loc.location = cia.location)
	select @sort_seq = 0
	SELECT @INV_AVL = @LAST_INV
	select @drp = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'drp' and sort_seq = @sort_seq + 1
	select @sls = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'sls' and sort_seq = @sort_seq + 1
	select @po = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'po' and sort_seq = @sort_seq + 1
	select @ord = sum(isnull(quantity,0)) from #sku where sku = @sku and line_type = 'ord' and sort_seq = @sort_seq + 1
END
-- final select


-- fixup
select distinct
-- #style.*
#style.brand
,#style.style
,specs.vendor
,specs.type_code
,specs.gender
,specs.material
,specs.moq
,specs.watch
,specs.sf
,CASE WHEN specs.rel_date = '1/1/1900' THEN NULL ELSE specs.rel_date END AS rel_date
 --= (select min(release_date) From cvo_inv_master_r2_vw where collection = i.category
	--	and model = ia.field_2)
,case when #style.pom_date = '1/1/1900' then null else #style.pom_date end as pom_date
,#style.mth_since_rel
,#style.[Sales m1-3] s_sales_m1_3
,#style.[Sales m1-12] s_sales_m1_12
,#style.s_e4_wu
,#style.s_e12_wu
,#style.s_e52_wu
,#style.s_promo_w4
,#style.s_promo_w12
,#style.s_gross_w4
,#style.s_gross_w12
-- , #SKU.*
,#sku.line_type
,#sku.sku
,#sku.mm
,case when #style.rel_date <> isnull(ia.field_26,#style.rel_date) 
	then ia.field_26 end as  p_rel_date
,case when #style.pom_date <> isnull(ia.field_28,#style.pom_date)
		then ia.field_28 end as p_pom_date
, (select lead_time from inv_list il 
	where il.part_no = #sku.sku and il.location = '001') lead_time
,#sku.bucket
,#sku.qoh
,#sku.atp
,#sku.reserve_qty
,#sku.quantity
,#sku.mult
,#sku.s_mult
,#sku.sort_seq
,#t.pct_of_style
,#t.pct_First_po
,#t.pct_sales_style_m1_3
,#t.p_e4_wu
,#t.p_e12_wu
,#t.p_e52_wu
,#t.p_subs_w4
,#t.p_subs_w12
,#t.s_mth_usg
,#t.p_mth_usg
,#t.s_mth_usg_mult
, p_po_qty_y1 = 
case when #sku.line_type = 'V' and #sku.sort_seq = 1 then
isnull((select sum(qty_ordered)  
From pur_list p (nolock)
inner join inv_master i (nolock) on i.part_no = p.part_no
inner join inv_master_add ia (nolock) on ia.part_no = i.part_no
where 1=1
and i.void = 'n'
AND P.VOID <> 'V' -- 8/3/2016
and p.part_no = #sku.sku 
and p.rel_date <= dateadd(yy,1,ia.field_26)
and p.type = 'p' and p.location = '001'
), 0) else 0 END,
CASE WHEN #style.pom_date IS NULL OR #style.pom_date = '1/1/1900' THEN r.ORDER_THRU_DATE 
	WHEN  #style.pom_date < r.ORDER_THRU_DATE THEN #style.pom_date
	ELSE r.order_thru_date END AS ORDER_THRU_DATE,
r.TIER, -- 7/8/2016
i.type_code p_type_code, -- res type of sku, not style - 11/1/2016
#t.s_rx_w4, -- 12/5/2016
#t.s_rx_w12,
#t.p_rx_w4,
#t.p_rx_w12,
#t.s_Ret_w4,
#t.s_ret_w12,
#t.p_ret_w4,
#t.p_ret_w12,
#t.s_wty_w4,
#t.s_wty_w12,
#t.p_wty_w4,
#t.p_wty_w12,
#t.p_gross_w4,
#t.p_gross_w12,
specs.price,
specs.frame_type

from #SKU 

inner join inv_master i (nolock) on #SKU.sku = i.part_no
inner join inv_master_add ia (nolock) on #SKU.sku = ia.part_no
inner join #style on #style.brand = i.category and #style.style = ia.field_2
inner join #t on #t.part_no = #sku.sku and #t.mm = #sku.mm 
	and #t.mult = #sku.mult and #t.sort_seq = #sku.sort_seq
inner join
(
SELECT  i.category brand ,
        ia.field_2 style ,
        i.vendor ,
        MAX(i.type_code) type_code ,
        MAX(category_2) gender ,
        -- MAX(i.cmdty_code) material ,
		MAX(ISNULL(ia.field_10,i.cmdty_code)) material, -- 12/12/2016
		MAX(ISNULL(ia.field_11,'UNKNOWN')) frame_type,
        MAX(ISNULL(ia.category_1, '')) watch ,
        ( SELECT TOP 1
                    MOQ_info
          FROM      cvo_Vendor_MOQ
          WHERE     Vendor_Code = i.vendor
        ) moq ,
        MAX(ISNULL(ia.field_32, '')) sf ,
        MIN(ISNULL(ia.field_26, '1/1/1900')) rel_date,
		MAX(pp.price_a) price
FROM    inv_master i ( NOLOCK )
        INNER JOIN inv_master_add ia ( NOLOCK ) ON ia.part_no = i.part_no
		INNER JOIN part_price pp (NOLOCK) ON pp.part_no = i.part_no
WHERE   1 = 1
        AND i.type_code IN ( 'frame', 'sun', 'bruit' )
        AND i.void = 'n'
        AND ISNULL(ia.field_32, '') <> 'SpecialOrd'
GROUP BY i.category ,
         ia.field_2 ,
         i.vendor
) as specs
on specs.brand = #style.brand and specs.style = #style.style

LEFT OUTER JOIN
cvo_ifp_rank r ON r.brand = #style.brand AND r.style = #style.style


end












GO
