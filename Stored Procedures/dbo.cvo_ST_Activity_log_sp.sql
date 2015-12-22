SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_ST_Activity_log_sp]
@startdate datetime 
, @enddate datetime 
, @Territory varchar(1000) = null
, @qualorder int = 1
, @detail INT = 0
as
 
-- add RMA figures - 6/19/2014
-- exec cvo_ST_Activity_log_sp '01/02/2015','02/28/2015', null, 1

/*
declare @startdate datetime, @enddate datetime
set @startdate = '06/10/2014'
set @enddate = '07/19/2014'

declare @territory varchar(20)
set @territory = '90614'
*/

-- exec cvo_ST_Activity_log_sp '01/01/2015','02/28/2015', '20210'

if(object_id('tempdb.dbo.#temp') is not null) drop table #temp
if(object_id('tempdb.dbo.#territory') is not null) drop table #territory
if(object_id('tempdb.dbo.#finalselect') is not null) drop table #finalselect

declare @where varchar(1024)

create table #territory (territory varchar(10))
if @Territory is null
begin
 insert into #territory (territory)
 select distinct territory_code from armaster (nolock)
end
else
begin
 insert into #territory (territory)
 select listitem from dbo.f_comma_list_to_table(@Territory)
end

SELECT 
	o.order_no, o.ext, 
	o.cust_code, o.ship_to, o.ship_to_name, 
	o.location, o.cust_po, 
	o.routing, o.fob, o.attention, 
	o.tax_id, o.terms, o.curr_key, 
	o.salesperson, 
	space(60) as salesperson_name, 
	o.Territory, o.total_amt_order, o.total_discount, o.total_tax, o.freight, 
	o.qty_ordered, o.qty_shipped, o.total_invoice, o.invoice_no, o.doc_ctrl_num, o.date_invoice, 
	o.date_sch_ship, o.date_shipped, o.status, 
	CASE o.status WHEN 'A' THEN 'Hold' 
	WHEN 'B' THEN 'Credit Hold' 
	WHEN 'C' THEN 'Credit Hold' 
	WHEN 'E' THEN 'Other' WHEN 'H' THEN 'Hold' WHEN 'M' THEN 'Other'
	WHEN 'N' THEN 'Received' WHEN 'P' THEN CASE WHEN isnull
	((SELECT TOP (1) c.status
	FROM   tdc_carton_tx c(nolock)
	WHERE o.order_no = c.order_no AND o.ext = c.order_ext AND (c.void = 0 OR
				c.void IS NULL)), '') IN ('F', 'S', 'X') 
	THEN 'Shipped' ELSE 'Processing' END 
	WHEN 'Q' THEN 'Processing' 
	WHEN 'R' THEN 'Shipped' 
	WHEN 'S' THEN 'Shipped' 
	WHEN 'T' THEN 'Shipped' 
	WHEN 'V' THEN 'Void'
	WHEN 'X' THEN 'Void' ELSE '' END AS status_desc, 
	o.who_entered, o.shipped_flag, o.hold_reason, 
	o.orig_no, o.orig_ext, o.promo_id, o.promo_level, o.order_type, 
	o.FramesOrdered, o.FramesShipped, 0 as FramesRMA, o.back_ord_flag, o.Cust_type, 
	o.HS_order_no, o.source

into #temp

FROM  cvo_adord_vw AS o WITH (nolock) 
inner join #territory t on t.territory = o.territory
where 1=1
and o.status <> 'V'
AND (o.date_entered BETWEEN @StartDate AND dateadd(ms, -3, dateadd(dd, datediff(dd,0,@EndDate)+1, 0)))
and o.date_sch_ship between @startdate and @enddate 
and isnull(o.date_shipped,@enddate) <= @enddate
AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
and o.order_type like 'ST%'
and right(o.order_type,2) not in ('RB','TB')
and (o.total_amt_order - o.total_discount) > 0.00
and 0 < isnull(framesordered,0) 

-- tally up credit returns too

insert into #temp
select distinct

	o.order_no, o.ext, 
	o.cust_code, o.ship_to, o.ship_to_name, 
	o.location, o.cust_po, 
	o.routing, o.fob, o.attention, 
	o.tax_id, o.terms, o.curr_key, 
	o.salesperson, 
	space(60) as salesperson_name, 
	o.ship_to_region as Territory, 
	total_amt_order = 
	(case o.status 	when 'T' then o.gross_sales	else  o.total_amt_order end)*-1,
	total_discount= 
	(case o.status 	when 'T' then o.total_discount 	else o.tot_ord_disc end)*-1,
	total_tax =
	(case o.status 	when 'T' then o.total_tax 	else o.tot_ord_tax 	end)*-1,        
	freight=
	(case o.status 	when 'T' then o.freight else o.tot_ord_freight 	end)*-1,        
	0 as qty_ordered, 
	0 as qty_shipped, 
	total_invoice = 
	(case o.status 	when 'T' then o.total_invoice
	else (o.total_amt_order-o.tot_ord_disc+o.tot_ord_tax+o.tot_ord_freight) end)*-1, 
	convert(varchar(10),o.invoice_no) invoice_no ,        
	oi.doc_ctrl_num,
	date_invoice = o.invoice_date ,           
	date_sch_ship = o.sch_ship_date ,
	o.date_shipped, 
	o.status, 
	CASE o.status WHEN 'A' THEN 'Hold' 
	WHEN 'B' THEN 'Credit Hold' 
	WHEN 'C' THEN 'Credit Hold' 
	WHEN 'E' THEN 'Other' WHEN 'H' THEN 'Hold' WHEN 'M' THEN 'Other'
	WHEN 'N' THEN 'Received' WHEN 'P' THEN CASE WHEN isnull
	((SELECT TOP (1) c.status
	FROM   tdc_carton_tx c(nolock)
	WHERE o.order_no = c.order_no AND o.ext = c.order_ext AND (c.void = 0 OR
				c.void IS NULL)), '') IN ('F', 'S', 'X') 
	THEN 'Shipped' ELSE 'Processing' END 
	WHEN 'Q' THEN 'Processing' 
	WHEN 'R' THEN 'Shipped' 
	WHEN 'S' THEN 'Shipped' 
	WHEN 'T' THEN 'Shipped' 
	WHEN 'V' THEN 'Void'
	WHEN 'X' THEN 'Void' ELSE '' END AS status_desc, 
	o.who_entered, 
	shipped_flag =        
	CASE o.status        
	WHEN 'A' THEN 'No'        
	WHEN 'B' THEN 'No'        
	WHEN 'C' THEN 'No'        
	WHEN 'E' THEN 'No'        
	WHEN 'H' THEN 'No'        
	WHEN 'M' THEN 'No'        
	WHEN 'N' THEN 'No'        
	WHEN 'P' THEN 'No'        
	WHEN 'Q' THEN 'No'        
	WHEN 'R' THEN 'Yes'        
	WHEN 'S' THEN 'Yes'        
	WHEN 'T' THEN 'Yes'        
	WHEN 'V' THEN 'No'        
	WHEN 'X' THEN 'No'        
	ELSE ''        
	END,        
	o.hold_reason, 
	o.orig_no, o.orig_ext, co.promo_id, co.promo_level, 'ST' as order_type, 
	0 as FramesOrdered, 0 as FramesShipped, 
	isnull((select sum(ol.cr_ordered) 
		from ord_list ol (nolock) 
		join inv_master i on ol.part_no = i.part_no
		where o.order_no = ol.order_no and o.ext = ol.order_ext
		and i.type_code in ('frame','sun') ), 0) as FramesRMA, 
	o.back_ord_flag, 
	isnull(ar.addr_sort1,'') as Cust_type,
	isnull(o.user_def_fld4,'') as HS_order_no, 
	'C' as source

from orders o (nolock)
inner join #territory t on t.territory = o.ship_to_region
inner join #temp on #temp.cust_code = o.cust_code and #temp.ship_to = o.ship_to
-- hs_order_no = isnull(o.user_def_fld4,'') -- only related to an order
join cvo_orders_all co on co.order_no = o.order_no and co.ext = o.ext
left outer join orders_invoice oi on oi.order_no = o.order_no and oi.order_ext = o.ext
join armaster ar on ar.customer_code = o.cust_code and ar.ship_to_code = o.ship_to
where o.type = 'c'
and o.status <> 'v'
and o.date_entered between @startdate and dateadd(ms, -3, dateadd(dd, datediff(dd,0,@EndDate)+1, 0))
-- and o.hold_reason = isnull((select top 1 value_str from config where flag = 'CR_UPLOAD_HOLD_RES'),'xxx')
and exists (select 1 from ord_list ol where ol.order_no = o.order_no and ol.order_ext = o.ext and ol.return_code like '06%')

-- create framework of rep. list in case covering a territory with no activity

    insert into #temp (Territory, salesperson, salesperson_name, cust_code, ship_to, ship_to_name, source, tax_id
		, status_desc, shipped_flag, cust_type, hs_order_no, FramesOrdered,FramesShipped, FramesRMA )
    SELECT   distinct a.territory_code, 
    a.salesperson_code,
	slp.salesperson_name
	,'' , '', '', 'T', '', '', '', '', '', 0,0, 0
    
	FROM  armaster (nolock) a 
	inner join #territory t on t.territory = a.territory_code
	inner join arsalesp slp (nolock) on slp.salesperson_code = a.salesperson_code
	where a.territory_code is not null
    and a.salesperson_code <> 'smithma'
    and a.status_type = 1 -- active accounts only
    

-- select * from #temp 

-- Final Select 

select 
isnull(cust_code,'') cust_code,
ship_to = isnull(#temp.ship_to,''),
ship_To_door = case when ca.door = 0 then '' else isnull(#temp.ship_to,'') end,
ship_to_name,
salesperson,
max(isnull(#temp.salesperson_name,salesperson)) salesperson_name,
Territory,
dbo.calculate_region_fn(Territory) region, -- 10/31/2013
sum(total_amt_order) total_amt_order,
sum(total_discount) total_discount ,
sum(total_tax) total_tax,
sum(freight) freight,
sum(qty_ordered) qty_ordered,
sum(qty_shipped) qty_shipped,
sum(total_invoice) total_invoice,
sum(FramesOrdered) FramesOrdered,
sum(FramesShipped) FramesShipped,
sum(FramesRMA) FramesRMA
--,Qual_order = case when ((isnull(framesordered,0) - isnull(framesrma,0)) > 4 
--	and total_amt_order <> 0.0
--	and date_sch_ship between @startdate and @enddate 
--	and isnull(date_shipped,@enddate) <= @enddate) then 1 
--	when source = 't' then 1 
--	-- when framesrma <> 0 then 1
--	else 0 end

into #finalselect

from #temp
left outer join cvo_armaster_all ca (nolock) 
on ca.customer_code = #temp.cust_code and ca.ship_to = #temp.ship_to
left outer join arsalesp slp (nolock) on slp.salesperson_code = #temp.salesperson 
where 
(
isnull(framesrma,0) > 0 
or isnull(framesordered,0) > 0 
or source = 'T'
)
group by
isnull(cust_code,'') , isnull(#temp.ship_to,''), case when ca.door = 0 then '' else isnull(#temp.ship_to,'') end,
ship_to_name,
salesperson,
-- salesperson_name,
Territory
-- , dbo.calculate_region_fn(Territory)

--having
--( (sum(isnull(framesordered,0)) - sum(isnull(framesrma,0)) ) > 4 
--	and ( sum(total_amt_order) - sum(total_discount) ) <> 0.0 )
--	or isnull(cust_code,'') = ''

if @qualorder = 1 
select @where = '
    (framesordered - framesrma  > 4 
	 and  total_amt_order - total_discount <> 0.0)
	 or cust_code = '''' '
else
select @where = '
    (framesordered - framesrma  <= 4 
	 and  total_amt_order - total_discount <> 0.0)
	 or cust_code = '''' '

IF @detail = 0
EXEC('	select
	cust_code,
	ship_to ,
	ship_To_door,
	ship_to_name,
	salesperson,
	salesperson_name,
	Territory,
	region, -- 10/31/2013
	total_amt_order,
	total_discount ,
	total_tax,
	freight,
	qty_ordered,
	qty_shipped,
	total_invoice,
	FramesOrdered,
	FramesShipped,
	FramesRMA
	From #finalselect where ' + @where )
else
EXEC('	select * 
	From #temp where ' + @where )
GO
GRANT EXECUTE ON  [dbo].[cvo_ST_Activity_log_sp] TO [public]
GO
