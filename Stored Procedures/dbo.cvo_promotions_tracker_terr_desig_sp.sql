SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_promotions_tracker_terr_desig_sp]
-- @promo varchar(20), 
@sdate datetime, @edate datetime, @Terr varchar(1000) = null
, @Promo varchar(5000) = null, @PromoLevel varchar(5000) = null
-- updates
-- 10/30 - make promo multi-value list - need to repmove parameter
-- exec cvo_promotions_tracker_terr_desig_sp '1/1/2016','02/12/2016', null , 'bep,rxe'
as

-- 122614 put parameters into local variables to prevent 'sniffing'
-- 011816 - change who_entered criteria

declare @startdate datetime, @enddate datetime
set @startdate = @sdate
set @enddate = @edate

declare @territory varchar(1000)
set @territory = @Terr

create table #territory (territory varchar(10), region VARCHAR(3))
if @territory is null
begin
 insert into #territory (territory, region)
 select distinct territory_code, dbo.calculate_region_fn(territory_code) region from armaster (nolock)
 where status_type = 1 -- active accounts only
end
else
begin
 insert into #territory (territory, region)
 select listitem , dbo.calculate_region_fn(listitem) region FROM dbo.f_comma_list_to_table(@territory)
end

declare @promo_id varchar(5000), @promo_level varchar(5000)
select  @promo_id = @Promo, @promo_level = @PromoLevel

create table #promo_id (promo_id varchar(20))
if @promo_id is null
begin
	insert into #promo_id (promo_id)
	select distinct promo_id from cvo_promotions
	where void <> 'V' or void is null 
end
else
begin 
	insert into #promo_id (promo_id)
	select listitem from dbo.f_comma_list_to_table(@promo_id)
end

create table #promo_level (promo_level varchar(30))
if @promo_level is null
begin
	insert into #promo_level (promo_level)
	select distinct promo_level from cvo_promotions p
		inner join #promo_id pp on p.promo_id = pp.promo_id
	where void <> 'V' or void is null 
end
else
begin 
	insert into #promo_level (promo_level)
	select listitem from dbo.f_comma_list_to_table(@promo_level)
end

-- exec cvo_promotions_tracker_terr_sp '11/1/2013','10/31/2014' ,'20206'

SELECT o.order_no, o.ext, o.cust_code, o.ship_to, 
o.ship_to_name, o.location, o.cust_po, o.routing, o.fob, o.attention, o.tax_id
, o.terms, o.curr_key, 
ar.salesperson_code salesperson, 
ar.territory_code Territory, 
t.region,
o.total_amt_order, o.total_discount, o.total_tax, o.freight, o.qty_ordered, 
o.qty_shipped, o.total_invoice, o.invoice_no, o.doc_ctrl_num, o.date_invoice, 
               o.date_entered, o.date_sch_ship, o.date_shipped, o.status, 
               CASE o.status WHEN 'A' THEN 'Hold' WHEN 'B' THEN 'Credit Hold' WHEN 'C' THEN 'Credit Hold' WHEN 'E' THEN 'Other' WHEN 'H' THEN 'Hold' WHEN 'M' THEN 'Other'
                WHEN 'N' THEN 'Received' WHEN 'P' THEN CASE WHEN isnull
                   ((SELECT TOP (1) c.status
                     FROM   tdc_carton_tx c(nolock)
                     WHERE o.order_no = c.order_no AND o.ext = c.order_ext AND (c.void = 0 OR
                                    c.void IS NULL)), '') IN ('F', 'S', 'X') 
               THEN 'Shipped' ELSE 'Processing' END WHEN 'Q' THEN 'Processing' WHEN 'R' THEN 'Shipped' WHEN 'S' THEN 'Shipped' WHEN 'T' THEN 'Shipped' WHEN 'V' THEN 'Void'
                WHEN 'X' THEN 'Void' ELSE '' END AS status_desc
, o.who_entered, o.shipped_flag, o.hold_reason, o.orig_no, o.orig_ext, o.promo_id, o.promo_level, o.order_type, 
               o.FramesOrdered, o.FramesShipped, o.back_ord_flag, o.Cust_type, 
cast('1/1/1900' as datetime) as return_date,
space(40) as reason,
cast(0.00 as decimal(20,8)) as return_amt,
0 as return_qty,
o.source
, uc = 0

into #temp

FROM  #territory t inner join cvo_adord_vw AS o WITH (nolock) on t.territory = o.territory
inner join #promo_id p on p.promo_id = o.promo_id
inner join #promo_level pl on pl.promo_level = o.promo_level
inner join armaster ar (nolock) on ar.customer_code = o.cust_code and ar.ship_to_code = o.ship_to
where 1=1
and isnull(o.promo_id,'') NOT IN ('', 'RXE') -- 10/31/2013

-- 10/30/2013 WHERE (o.promo_id IN (@Promo)) 
/*
and (o.promo_id in (@PromoLevel)) 
*/
AND (o.date_entered BETWEEN @StartDate AND 
dateadd(ms, -3, dateadd(dd, datediff(dd,0,@EndDate)+1, 0)))
-- AND (o.Territory IN (@Territory)) 
AND o.who_entered <> 'backordr' -- 1/18/2016
-- AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
-- AND              (o.order_type <> 'st-rb') 
and o.status <> 'V' -- 110714 - exclude void orders

-- look for split international orders -- TBD

-- Collect the returns

select o.orig_no order_no, o.orig_ext ext,
	return_date = o.date_entered, 
	reason = min(rc.return_desc)
into #r
from #temp t inner join  orders o (nolock) on t.order_no = o.orig_no and t.ext = o.orig_ext
 inner join ord_list ol (nolock) on   ol.order_no = o.order_no and ol.order_ext = o.ext
 INNER JOIN inv_master i(nolock) ON ol.part_no = i.part_no 
 INNER JOIN po_retcode rc(nolock) ON ol.return_code = rc.return_code
 WHERE 1=1
 -- and LEFT(ol.return_code, 2) <> '05' -- AND i.type_code = 'sun'
  AND o.status = 't' and o.type = 'c' 
  and (o.total_invoice = t.total_invoice or o.total_amt_order = t.total_amt_order)
group by o.orig_no, o.orig_ext, o.date_entered, o.total_amt_order -- o.total_invoice



update t set 
t.return_date = #r.return_date,
t.reason = #r.reason
from #r , #temp t where #r.order_no = t.order_no and #r.ext = t.ext

--select * from #r
--select * From #temp

-- delete from #temp where order_no = 1639532 -- manual exclusion

-- make sure you have all territories in output, even if no data exists

    SELECT   distinct s.territory_code, t.region,
    s.salesperson_code
    into #reps
    FROM  #territory t 
	-- inner join armaster (nolock) a on t.territory = a.territory_code 
	inner join arsalesp (nolock) s on s.territory_code = t.territory
	where s.territory_code is not null
    and s.salesperson_code <> 'smithma'
    -- and a.status_type = 1 -- active accounts only
	and s.status_type = 1
    
    select distinct promo_id , promo_level, status 
    into #promos
    from #temp
    
    insert into #temp (Territory, region, salesperson, cust_code, ship_to, ship_to_name, tax_id, date_entered, status, status_desc, shipped_flag, framesordered, framesshipped, cust_type, return_qty, source, uc, promo_id, promo_level )
    SELECT   #reps.territory_code, #reps.region, #reps.salesperson_code, '' , '', '','', @enddate, #promos.status,'','',0,0,'',0,'T', 0,  #promos.promo_id, #promos.promo_level
    FROM  #reps cross join #promos
 
	update t set uc = 1
	from 
	(select cust_code, promo_id, min(order_no) min_order from #temp 
		inner join cvo_armaster_all car (nolock) on car.customer_code = #temp.cust_code
			and car.ship_to = #temp.ship_to
		where source <> 'T' and (isnull(reason,'') = '' 
		and not exists (select 1 from cvo_promo_override_audit poa 
			where poa.order_no = #temp.order_no and poa.order_ext = #temp.ext))
		and car.door = 1
		group by cust_code, promo_id
	) as m 	inner join #temp t 
	on t.cust_code = m.cust_code and t.promo_id = m.promo_id and t.order_no = m.min_order
   

IF EXISTS (SELECT 1 FROM #promo_id AS p WHERE p.promo_id = 'RXE') 
BEGIN -- get enrollment info for the reporting period
	INSERT INTO #temp
			( cust_code ,
			  Cust_type,
			  cust_po ,
			  salesperson ,
			  Territory ,
			  region ,
			  tax_id,
			  status_desc,
			  date_entered ,
			  date_shipped ,
			  shipped_flag,
			  who_entered ,
			  promo_id ,
			  promo_level ,
			  FramesOrdered,
			  FramesShipped,
			  return_qty,
			  source,
			  uc
			)
	SELECT  distinct
	ccdc.customer_code AS cust_code,
	ar.addr_sort1 AS cust_type,
	'RXE Enroll' AS cust_po,
	ar.salesperson_code,
	ar.territory_code,
	dbo.calculate_region_fn(ar.territory_code),
	'' AS tax_id,
	'' AS status_desc,
	ccdc.start_date,
	ccdc.start_date,
	'Yes' AS shipped_flag,
	'RXE Enroll',
	'RXE',
	ccdc.code,
	0,
	0,
	0,
	'D',
	0
	FROM dbo.cvo_cust_designation_codes AS ccdc
	JOIN armaster ar ON ar.customer_code = ccdc.customer_code
	WHERE code LIKE 'rx%'
	AND ar.address_type = 0
	AND ccdc.start_date BETWEEN @StartDate AND 
	dateadd(ms, -3, dateadd(dd, datediff(dd,0,@EndDate)+1, 0))
END

select distinct
order_no,
ext,
cust_code,
ship_to,
ship_to_name,
location,
cust_po,
routing,
fob,
attention,
tax_id,
terms,
curr_key,
salesperson,
Territory,
region, 
total_amt_order,
total_discount,
total_tax,
freight,
qty_ordered,
qty_shipped,
isnull(total_invoice,0) total_invoice,
invoice_no,
doc_ctrl_num,
date_invoice,
date_entered,
date_sch_ship,
date_shipped,
status,
-- 022714 - tag - fineline the reason for the disqualification on rebills
--  you'll find the rebill order later as a qualified order
case when reason='Credit & Rebill' then 'Credit/Rebill' else status_desc end as status_desc,
who_entered,
shipped_flag,
hold_reason,
orig_no,
orig_ext,
promo_id,
promo_level,
order_type,
FramesOrdered,
FramesShipped,
back_ord_flag,
Cust_type,
return_date,
ltrim(rtrim(reason)) reason,
isnull(return_amt,0) return_amt,
isnull(return_qty,0) return_qty,
source,
Qual_order = case when source = 'T' then 0 
WHEN source = 'D' THEN 1
when isnull(reason,'') = '' and not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = #temp.order_no and poa.order_ext = #temp.ext) then 1 
else 0 end,	
(select top 1 ltrim(rtrim(failure_reason)) from cvo_promo_override_audit poa where poa.order_no = #temp.order_no and poa.order_ext = #temp.ext order by override_date desc) override_reason
, UC  
-- 2/10/16 - for region weekly summary
,Convert(varchar, DateAdd(dd, 1-(DatePart(dw,date_entered) - 1),date_entered), 101) wk_Begindate
,Convert(varchar, DateAdd(dd, (9 - DatePart(dw, date_entered)), date_entered), 101) wk_EndDate

from #temp


GO
