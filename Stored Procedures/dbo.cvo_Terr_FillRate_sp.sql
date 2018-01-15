SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_Terr_FillRate_sp]
@startdate datetime, @enddate datetime
as
 
-- add RMA figures - 6/19/2014
-- exec cvo_terr_fillrate_sp '06/18/2014','06/18/2014'

 /*
declare @startdate datetime, @enddate datetime
set @startdate = '06/01/2014'
set @enddate = '06/19/2014'

declare @territory varchar(20)
set @territory = '90614'

--*/

-- exec cvo_terr_fillrate_sp '12/1/2015','12/15/2015' 

DECLARE @sd datetime, @ed DATETIME
SELECT @sd = @startdate, @ed = dateadd(ms, -3, dateadd(dd, datediff(dd,0,@enddate)+1,0))

SELECT o.order_no, o.ext, 
o.cust_code, o.ship_to, o.ship_to_name, 
o.location, o.cust_po, 
o.routing, o.fob, o.attention, 
o.tax_id, o.terms, o.curr_key, 
o.salesperson, o.Territory, o.total_amt_order, o.total_discount, o.total_tax, o.freight, 
o.qty_ordered, o.qty_shipped, o.total_invoice, o.invoice_no, o.doc_ctrl_num, o.date_invoice, 
o.date_entered, o.date_sch_ship, o.date_shipped, o.status, 
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
                o.source

into #temp

FROM  cvo_adord_vw AS o WITH (nolock) 
where 1=1

AND (o.date_shipped BETWEEN @sd AND 
dateadd(ms, -3, dateadd(dd, datediff(dd,0,@ed)+1, 0)))
-- AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
AND o.who_entered <> 'backordr'
and o.order_type like 'ST%'
and right(o.order_type,2) not in ('RB','TB')

    SELECT   distinct a.territory_code, 
    a.salesperson_code,
	0 as FramesRMA
    into #reps
    FROM  armaster (nolock) a 
	where a.territory_code is not null
    and a.salesperson_code <> 'smithma'
    and a.status_type = 1 -- active accounts only

	;with rma as 
	(select o.ship_to_region territory, sum(ol.cr_ordered) FramesRMA
	from orders o join ord_list ol on o.order_no = ol.order_no and o.ext = ol.order_ext
	join inv_master i on ol.part_no = i.part_no
	where o.type = 'c' 
	and o.status < 'r'
	and o.date_entered between @sd and @ed
	and o.hold_reason = isnull((select top 1 value_str from config where flag = 'CR_UPLOAD_HOLD_RES'),'xxx')
	and i.type_code in ('frame','sun')
	group by o.ship_to_region
	) 
	update #reps set FramesRMA = isnull(rma.framesrma,0)
	from #reps 
	left outer join rma	
	on rma.territory = #reps.territory_code

       
    insert into #temp (Territory, salesperson, cust_code, ship_to, ship_to_name, tax_id, date_entered, status, status_desc, shipped_flag, cust_type, source, promo_id, promo_level, order_type, FramesOrdered,
    FramesShipped, FramesRMA )
    SELECT   #reps.territory_code, #reps.salesperson_code, '' , '', '','', 
		isnull(@ed,getdate()), '','','','','T', '', '','ST', 0,0, #reps.framesRMA
    FROM  #reps 
    

select distinct
#temp.order_no,
#temp.ext,
isnull(cust_code,'') cust_code,
isnull(#temp.ship_to,'') ship_to,
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
status_desc,
who_entered,
shipped_flag,
hold_reason,
orig_no,
orig_ext,
isnull(promo_id,'') promo_id,
isnull(promo_level,'') promo_level,
order_type,
FramesOrdered,
FramesShipped,
FramesRMA,
case when back_ord_flag = 0 then 'AB'
    when back_ord_flag = 1 then 'SC'
    when back_ord_flag = 2 then 'AP'
    end as back_ord_flg,
Cust_type,
case when ca.allow_substitutes = 0 then 'No'
    when ca.allow_substitutes = 1 then 'Yes' end as Allow_subs,
ISNULL((SELECT note FROM orders 
	WHERE order_no = #temp.order_no AND ext = #temp.ext), '') Order_note,
source
-- for mtd/ytd summary version
, mtd_ord = CASE WHEN DATEPART(MONTH,date_shipped) = DATEPART(MONTH,@ed) THEN FramesOrdered ELSE 0 END
, mtd_shp = CASE WHEN DATEPART(MONTH,date_shipped) = DATEPART(MONTH,@ed) THEN FramesShipped ELSE 0 end
from #temp
left outer join cvo_armaster_all ca (nolock) on ca.customer_code = #temp.cust_code and ca.ship_to = #temp.ship_to
where (isnull(framesordered,0) > 0 or source = 'T')
order by territory, order_type

GO
GRANT EXECUTE ON  [dbo].[cvo_Terr_FillRate_sp] TO [public]
GO
