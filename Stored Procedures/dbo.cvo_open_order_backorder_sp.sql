SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[cvo_open_order_backorder_sp] 
  @location varchar(10) = '001'
, @option int = 2
, @incl_parts int = 0

as

-- 022315 - tag - add additional po info, backorders only
-- 8/3/2015 - only include line items where the part has <0 qty avl

/*
exec [cvo_open_order_backorder_sp] '001', 4, 0
*/

-- option = 1 - promos
-- option = 2 - order type
-- option = 3 - vendor
-- option = 4 - part_no

--declare @location varchar(10), @option int, @incl_parts int
--set @location = '001'
--set @option = 2
--set @incl_parts = 0



-- exec cvo_open_order_backorder_sp '001', 4, 0

SET NOCOUNT ON;

declare @today datetime, @bo_hold varchar(2)
select @today = dateadd(dd, datediff(dd,0,getdate()), 0)
select @bo_hold = 'STIH'

IF (SELECT OBJECT_ID('tempdb..#type_code')) IS NOT NULL BEGIN DROP TABLE #type_code  END
create table #type_code (type_code varchar(10))
insert #type_code values ('frame')
insert #type_code values ('sun')
if @incl_parts = 1 insert #type_code values ('parts')
	
-- select @type_code
					 
-- open order lines

IF (SELECT OBJECT_ID('tempdb..#ool')) IS NOT NULL 
BEGIN DROP TABLE #ool  END
 
select ol.part_no,
case when @option = 1 then isnull(co.promo_id,'')
     when @option = 2 then left(o.user_category,2)
	 when @option = 4 then left(o.user_category,2) -- ol.part_no
    else '' end as  report_option,
ol.location,
ol.ordered-(ol.shipped + isnull(e.qty,0)) open_ord_qty,
case when datediff(d,o.sch_ship_date,@today) < 0 then 'Future'
	 when datediff(d,o.sch_ship_date,@today) = 0 then 'Current'
	 when datediff(d,o.sch_ship_date,@today) between 1 and 21 then '1-21'
	 when datediff(d,o.sch_ship_date,@today) between 22 and 42 then '22-42'
	 when datediff(d,o.sch_ship_date,@today) >42 then '43 +'
	 else 'N/A'
end as DaysOverDue

into #ool

From  inv_master inv  (nolock)
inner join #type_code on #type_code.type_code = inv.type_code
inner join ord_list ol (nolock) on inv.part_no = ol.part_no
inner join orders o (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext 
left outer join cvo_promotions p (nolock) on p.promo_id = co.promo_id and p.promo_level = co.promo_level
-- 3/4/15
left outer join cvo_hard_allocated_vw e (nolock) on
	e.order_no = o.order_no 
	and e.order_ext = o.ext 
	and e.line_no = ol.line_no
	and e.order_type = 's'
where 1=1 
-- and inv.type_code = ('frame','sun')
-- and ol.status in ('N','a') 
and ((o.status = 'a' and (o.hold_reason = @bo_hold)) or o.status = 'n')
and ol.ordered > (ol.shipped + isnull(e.qty,0))
and o.sch_ship_date < @today
and ol.location like @location
and ol.part_type = 'p'


-- select * from #ool

IF (SELECT OBJECT_ID('tempdb..#ool_summary')) IS NOT NULL 
BEGIN DROP TABLE #ool_summary  END

select part_no,
isnull(report_option,'') report_option,
isnull(location,'') location,
sum(open_ord_qty) open_ord_qty,
isnull(DaysOverDue,0) daysoverdue
into #ool_summary
from #ool
group by part_no, report_option, location, daysoverdue

CREATE NONCLUSTERED INDEX [idx_ool] ON #ool_summary
(	[location] asc, [part_no] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

IF (SELECT OBJECT_ID('tempdb..#cia')) IS NOT NULL 
BEGIN DROP TABLE #cia  END

;with ool as 
(select distinct part_no, location from #ool_summary)
select 
i.category as brand, 
ia.field_2 as style,
i.type_code as restype, 
ia.category_2 as gender, 
i.part_no, 
ia.field_28 as pom_date, --v1.1
-- 0 as qty_avl,
cia.qty_avl AS qty_avl,
cia.QcQty2 AS qty_rec, -- add rdock qty 5/4/17
ool.location,
r.NextPO, 
r.NextPOOnOrder,
r.NextPODueDate,
r.shipvia,
r.plrecd,
i.vendor,
case when @option = 3 then i.vendor else '' end as report_option
into #cia
from ool
inner join inv_master i (nolock) on ool.part_no = i.part_no
inner join inv_master_add ia (nolock) on ool.part_no = ia.part_no
-- 8/3/2015
INNER JOIN dbo.cvo_item_avail_vw cia (NOLOCK) ON cia.location = ool.location AND cia.part_no = i.part_no
left outer join 
(
 select top (100) percent 
  i.category brand
  , ia.field_2 style
  , rr.po_no NextPO
  , rr.part_no
  , rr.quantity-rr.received nextpoonorder
  , isnull(rr.inhouse_date, rr.confirm_date) NextPODueDate
  , rr.location
  , shipvia = case when pp.ship_via_method = 2 then 'BOAT' 
				   WHEN pp.ship_via_method = 1 THEN 'AIR' 
				   else ''
				   end	
  , plrecd = case when pp.plrecd = 1 then 'Yes-L'
				  when pa.expedite_flag = 1 then 'Yes-H'
				  else 'No' end
  , Row_Number() over(partition by rr.part_no, isnull(rr.inhouse_date, rr.confirm_date) 
		order by rr.part_no, rr.po_no, pp.plrecd desc, isnull(rr.inhouse_date, rr.confirm_date) ) AS po_rank
  from releases (nolock) rr 
  inner join pur_list (nolock) pp on pp.po_no = rr.po_no and pp.line = rr.po_line
  inner join purchase (nolock) pa on pa.po_no = rr.po_no
  inner join inv_master (nolock) i on i.part_no = rr.part_no
  inner join inv_master_add (nolock) ia on ia.part_no = rr.part_no
  where rr.quantity>rr.received and rr.status='O'
  and rr.location = @location
  and isnull(rr.inhouse_date,rr.confirm_date) = 
  (select min (isnull(inhouse_date,confirm_date)) from releases (nolock) where part_no = rr.part_no
	and location = rr.location and quantity>received and status='O' )
  order by i.category, ia.field_2, isnull(rr.inhouse_date, rr.confirm_date)

) as r on r.part_no = ool.part_no and r.location = ool.location and r.po_rank = 1

CREATE NONCLUSTERED INDEX [idx_cia] ON #cia
(	[location] asc, [part_no] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

-- select * From #cia

SELECT
    #cia.brand,
    #cia.style,
    #cia.restype,
    #cia.gender,
    #cia.part_no,
    #cia.pom_date,
    #cia.qty_avl,
    #cia.qty_rec,
    #cia.location,
    #cia.NextPO,
    #cia.NextPODueDate,
    #cia.nextpoonorder,
    #cia.shipvia,
    #cia.plrecd,
    #cia.vendor,
    CASE
        WHEN #cia.report_option <> '' THEN
            #cia.report_option
        ELSE
            ool.report_option
    END AS report_option,
    ool.open_ord_qty,
    ool.daysoverdue
FROM
    #cia
    LEFT OUTER JOIN #ool_summary ool
        ON #cia.part_no = ool.part_no
           AND #cia.location = ool.location
-- 8/3/2015
WHERE #cia.qty_avl < 0
;



GO
GRANT EXECUTE ON  [dbo].[cvo_open_order_backorder_sp] TO [public]
GO
