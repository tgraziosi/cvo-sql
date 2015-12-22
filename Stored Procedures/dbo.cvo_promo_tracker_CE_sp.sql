SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create PROCEDURE [dbo].[cvo_promo_tracker_CE_sp]
-- @promo varchar(20), 
@startdate datetime, @enddate datetime
-- updates
-- 10/30 - make promo multi-value list - need to repmove parameter
 /*
declare @promo varchar (20)
set @promo = 'bcbg'

declare @startdate datetime, @enddate datetime
set @startdate = '07/31/2013'
set @enddate = '9/26/2013'

declare @territory varchar(20)
set @territory = '90614'
 */
as

-- exec cvo_promotions_tracker_r2_sp '12/23/2013','02/27/2014' 

SELECT o.order_no, o.ext, o.cust_code, o.ship_to, o.ship_to_name, o.location, o.cust_po, o.routing, o.fob, o.attention, o.tax_id, o.terms, o.curr_key, o.salesperson, 
               o.Territory, o.total_amt_order, o.total_discount, o.total_tax, o.freight, o.qty_ordered, o.qty_shipped, o.total_invoice, o.invoice_no, o.doc_ctrl_num, o.date_invoice, 
               o.date_entered, o.date_sch_ship, o.date_shipped, o.status, 
               CASE o.status WHEN 'A' THEN 'Hold' WHEN 'B' THEN 'Credit Hold' WHEN 'C' THEN 'Credit Hold' WHEN 'E' THEN 'Other' WHEN 'H' THEN 'Hold' WHEN 'M' THEN 'Other'
                WHEN 'N' THEN 'Received' WHEN 'P' THEN CASE WHEN isnull
                   ((SELECT TOP (1) c.status
                     FROM   tdc_carton_tx c(nolock)
                     WHERE o.order_no = c.order_no AND o.ext = c.order_ext AND (c.void = 0 OR
                                    c.void IS NULL)), '') IN ('F', 'S', 'X') 
               THEN 'Shipped' ELSE 'Processing' END WHEN 'Q' THEN 'Processing' WHEN 'R' THEN 'Shipped' WHEN 'S' THEN 'Shipped' WHEN 'T' THEN 'Shipped' WHEN 'V' THEN 'Void'
                WHEN 'X' THEN 'Void' ELSE '' END AS status_desc, o.who_entered, o.shipped_flag, o.hold_reason, o.orig_no, o.orig_ext, o.promo_id, o.promo_level, o.order_type, 
               o.FramesOrdered, o.FramesShipped, o.back_ord_flag, o.Cust_type, 
cast('1/1/1900' as datetime) as return_date,
space(40) as reason,
cast(0.00 as decimal(20,8)) as return_amt,
0 as return_qty,
o.source

into #temp

FROM  cvo_adord_vw AS o WITH (nolock) 
where 1=1
and isnull(promo_id,'') <> '' -- 10/31/2013
-- 10/30/2013 WHERE (o.promo_id IN (@Promo)) 
/*
and (o.promo_id in (@PromoLevel)) 
*/
AND (o.date_entered BETWEEN @StartDate AND 
dateadd(ms, -3, dateadd(dd, datediff(dd,0,@EndDate)+1, 0)))
-- AND (o.Territory IN (@Territory)) 
AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
-- AND              (o.order_type <> 'st-rb') 
and o.status <> 'V' -- 110714 - exclude void orders

-- look for split international orders -- TBD

-- Collect the returns

select o.orig_no order_no, o.orig_ext ext,
	return_date = o.date_entered, 
	reason = min(rc.return_desc),
	return_amt =  o.total_invoice,
	return_qty = sum(cr_shipped) 
into #r
from #temp t inner join  orders o (nolock) on t.order_no = o.orig_no and t.ext = o.orig_ext
 inner join ord_list ol (nolock) on   ol.order_no = o.order_no and ol.order_ext = o.ext
 INNER JOIN inv_master i(nolock) ON ol.part_no = i.part_no 
 INNER JOIN po_retcode rc(nolock) ON ol.return_code = rc.return_code
 WHERE 1=1
 -- and LEFT(ol.return_code, 2) <> '05' -- AND i.type_code = 'sun'
  AND o.status = 't' and o.type = 'c' 
  and o.total_invoice = t.total_invoice
group by o.orig_no, o.orig_ext, o.date_entered, o.total_invoice

--select * from #r
--select * From #temp

update t set 
t.return_date = #r.return_date,
t.reason = #r.reason,
t.return_amt = #r.return_amt,
t.return_qty = #r.return_qty
from #r , #temp t where #r.order_no = t.order_no and #r.ext = t.ext

-- delete from #temp where order_no = 1639532 -- manual exclusion

-- make sure you have all territories in output, even if no data exists

    SELECT   distinct a.territory_code, 
    a.salesperson_code
    into #reps
    FROM  armaster (nolock) a where a.territory_code is not null
    and a.salesperson_code <> 'smithma'
    and a.status_type = 1 -- active accounts only
    
    select distinct promo_id, promo_level 
    into #promos
    from #temp
    
    insert into #temp (Territory, salesperson, cust_code, ship_to, ship_to_name, tax_id, date_entered, status, status_desc, shipped_flag, framesordered, framesshipped, cust_type, return_qty, source, promo_id, promo_level )
    SELECT   #reps.territory_code, #reps.salesperson_code, '' , '', '','', @enddate, '','','',0,0,'',0,'T', #promos.promo_id, #promos.promo_level
    FROM  #reps cross join #promos
    

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
dbo.calculate_region_fn(Territory) region, -- 10/31/2013
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
return_amt,
return_qty,
source,
Qual_order = case when source = 'T' then 0 
when isnull(return_amt,0) = 0 and not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = #temp.order_no and poa.order_ext = #temp.ext) then 1 
else 0 end,	
(select top 1 ltrim(rtrim(failure_reason)) from cvo_promo_override_audit poa where poa.order_no = #temp.order_no and poa.order_ext = #temp.ext order by override_date desc) override_reason
from #temp

GO
