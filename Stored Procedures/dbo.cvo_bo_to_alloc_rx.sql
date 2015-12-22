SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_bo_to_alloc_rx] 
as 

-- RX backorders to allocate
-- exec cvo_bo_to_alloc_rx
-- 030915 - change safety stock figure based on pom date

set nocount on

declare @ss int -- safety stock level for reserve
select @ss = 5

declare @today datetime, @bo_hold varchar(2)
select @today = dateadd(dd, datediff(dd,0,getdate()), 0)
select @bo_hold = 'xx'

IF OBJECT_ID('tempdb..#t') IS NOT NULL DROP TABLE #t


select o.order_no, o.ext, ol.line_no, o.user_category, o.date_entered, 
i.category brand, ia.field_2 style, ia.category_5 color_code, 
ia.field_19 a_size, ol.part_no, i.type_code
, case when ia.field_28 > @today then null else ia.field_28 end as  pom_date
, ss = case when isnull(ia.field_28,getdate()) < dateadd(yy,-1,@today) then 0 else 5 end
, ol.location, ol.ordered-ol.shipped open_qty
, -1 as qty_to_alloc, 0 as qty_avl_to_alloc, 0 as reserveqty, 0 as quarantine, space(12) as nextpoduedate
, 0 as DDTONEXTPO
, OL.NOTE
, O.PHONE
, O.ATTENTION
, o.ship_to_name 
, o.cust_code
, o.ship_to
, i.description
, bo_days = datediff(d,o.sch_ship_date,@today)
, case when datediff(d,o.sch_ship_date,@today) < 0 then 'Future'
	 when datediff(d,o.sch_ship_date,@today) = 0 then 'Current'
	 when datediff(d,o.sch_ship_date,@today) between 1 and 21 then '1-21'
	 when datediff(d,o.sch_ship_date,@today) between 22 and 42 then '22-42'
	 when datediff(d,o.sch_ship_date,@today) >42 then '43 +'
	 else 'N/A'
end as DaysOverDue
into #t
from orders o (nolock)
inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
left outer join cvo_promotions p (nolock) on p.promo_id = co.promo_id and p.promo_level = co.promo_level
inner join ord_list ol (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
inner join cvo_ord_list col (nolock) on col.order_no = ol.order_no and col.order_ext = ol.order_ext and col.line_no = ol.line_no
inner join inv_master i (nolock) on ol.part_no = i.part_no
inner join inv_master_add ia (nolock) on ol.part_no = ia.part_no
left outer join cvo_hard_allocated_vw alloc (nolock) 
	on alloc.order_no = o.order_no 
	and alloc.order_ext = o.ext
	and alloc.line_no = ol.line_no
	and alloc.order_type = 'S'
where 1=1
-- and  o.status ='N' 
and ((o.status = 'a' and (o.hold_reason = @bo_hold or p.hold_reason = @bo_hold)) or o.status = 'n')
and o.type = 'i' 
-- and o.who_entered in ('backordr','outofstock')
and o.sch_ship_date < @today
and ol.ordered > (ol.shipped + isnull(alloc.qty,0))
and i.type_code <>  'case'
and (o.user_category like 'rx%' or o.user_category = 'st-tr')
and col.is_customized = 'n'
and ol.part_type = 'p'

create index idx_t on #t (order_no, ext, location, part_no) include (open_qty, qty_to_alloc)

-- get reserve allocations
IF OBJECT_ID('tempdb..#ra') IS NOT NULL DROP TABLE #ra
select t.location, t.part_no, sum(t.qty) r_alloc 
into #ra
		from tdc_soft_alloc_tbl t (nolock)
		join tdc_bin_master b (nolock)
		on b.bin_no = t.bin_no and t.location = b.location and b.group_code = 'reserve'
		group by t.location, t.part_no

-- for each sku, consume the avail inventory

declare @loc varchar(12), @part varchar(40), @qty_avl_to_alloc int, @line_no int,
	    @order int, @ext int, @open_qty int, @qty_to_alloc int, 
		@reserveqty int, @quarantine int,
		@nextpoduedate datetime

select @loc = ''
select @part = ''
select @loc = min(isnull(location,'')) From #t where location > @loc
-- select @loc
select @part = min(isnull(part_no,'')) from #t where location = @loc and part_no > @part
-- select @part

select @ss = ss from #t where location = @loc and part_no = @part

select @qty_avl_to_alloc = isnull(reserveqty,0) - @ss - isnull(#ra.r_alloc,0)
	, @reserveqty = isnull(reserveqty,0) - isnull(#ra.r_alloc,0)
	, @quarantine = isnull(quarantine,0), @nextpoduedate = nextpoduedate
				  from cvo_item_avail_vw cia
				  left outer join #ra on #ra.location = @loc and #ra.part_no = @part
				  where cia.location = @loc and cia.part_no = @part and qty_avl <=0.
update #t set nextpoduedate = @nextpoduedate, 
	DDTONEXTPO = datediff(DD,@today,ISNULL(@nextpoduedate,'12/31/2020')) 
	where #t.part_no = @part
-- select @qty_avl
 

While @loc is not null
begin
	while @part is not null
	begin
		while @qty_avl_to_alloc > 0
		begin
			select top 1 @order = isnull(#t.order_no,-1), @ext = isnull(#t.ext,0) 
				, @line_no = isnull(#t.line_no,0), @open_qty = isnull(#t.open_qty,0) from #t
				where #t.part_no = @part and #t.location = @loc
				and #t.qty_to_alloc = -1
				order by #t.order_no asc 
			if @order = -1 break
			select @qty_to_alloc = case when @qty_avl_to_alloc >= @open_qty then @open_qty else @qty_avl_to_alloc end
			update #t set #t.qty_to_alloc = @qty_to_alloc, #t.qty_avl_to_alloc = @qty_avl_to_alloc
			, #t.reserveqty = @reserveqty -- , #t.quarantine = @quarantine -- , #t.nextpoduedate = @nextpoduedate
				where order_no = @order and ext = @ext and line_no = @line_no and location = @loc and part_no = @part
			select @qty_avl_to_alloc = @qty_avl_to_alloc - @qty_to_alloc
			-- select 'qty', @loc loc, @part part , @qty_avl qty_avl
		end -- qty
		select @part = min(isnull(part_no,'')) from #t where location = @loc and part_no > @part
		if @part = '' break
		
		select @ss = ss from #t where location = @loc and part_no = @part

		select @qty_avl_to_alloc = isnull(reserveqty,0) - @ss - isnull(#ra.r_alloc,0)
			, @reserveqty = isnull(reserveqty,0) - isnull(#ra.r_alloc,0)
			, @quarantine = isnull(quarantine,0), @nextpoduedate = nextpoduedate
				  from cvo_item_avail_vw cia
				  left outer join #ra on #ra.location = @loc and #ra.part_no = @part
				  where cia.location = @loc and cia.part_no = @part and qty_avl <=0.
		-- select 'part', @loc loc, @part part , @qty_avl qty_avl
		update #t set quarantine = ISNULL(@quarantine,0), nextpoduedate = @nextpoduedate, 
			DDTONEXTPO = datediff(DD,@today,ISNULL(@nextpoduedate,'12/31/2020')) 
			where #t.part_no = @part
	end -- part
	select @loc = min(isnull(location,'')) From #t where location > @loc
	if @loc = '' break
	select @part = min(isnull(part_no,'')) from #t where location = @loc and part_no > @part
	if @part = ''  break
	select @ss = ss from #t where location = @loc and part_no = @part

	select @qty_avl_to_alloc = isnull(reserveqty,0) - @ss - isnull(#ra.r_alloc,0)
		, @reserveqty = isnull(reserveqty,0) - isnull(#ra.r_alloc,0)
		, @quarantine = isnull(quarantine,0), @nextpoduedate = nextpoduedate
				  from cvo_item_avail_vw cia
				  left outer join #ra on #ra.location = @loc and #ra.part_no = @part
				  where cia.location = @loc and cia.part_no = @part and qty_avl <=0.
		update #t set quarantine = ISNULL(@quarantine,0), nextpoduedate = @nextpoduedate, 
			DDTONEXTPO = datediff(DD,@today,ISNULL(@nextpoduedate,'12/31/2020')) 
			where #t.part_no = @part
	-- select ' loc', @loc loc, @part part , @qty_avl qty_avl

end -- location


--select #qty.*,#t.order_no, #t.ext, #t.open_qty, #t.qty_to_alloc from #qty
--join #t on #qty.part_no = #t.part_no and #qty.location = #t.location

select brand, style, 
-- color_code, a_size, 
part_no, type_code, pom_date, ss, order_no, ext, 
-- line_no, 
user_category, date_entered, location, open_qty, qty_to_alloc, 
-- qty_avl_to_alloc, 
reserveqty, 
reserve_bin = (select top 1 lbs.bin_no from lot_bin_stock lbs
					join tdc_bin_master bm 
					on bm.location = lbs.location and bm.bin_no = lbs.bin_no 
						and bm.group_code = 'RESERVE'
					where lbs.part_no = #t.part_no and lbs.location = #t.location 
						and lbs.qty >= qty_avl_to_alloc),
quarantine, 
isnull(nextpoduedate,'') nextpoduedate
, DDTONEXTPO
, NOTE
, case when len(phone)=10 then substring(phone,1,3)+'-'+substring(PHONE,4,3)+'-'+substring(phone,7,4)
	else phone end as phone
, ATTENTION
, ship_to_name 
, cust_code
, ship_to
, description
, bo_days
, DaysOverDue
from #t 

where 1=1
-- and qty_to_alloc > 0 
order by part_NO, qty_avl_to_alloc desc

GO
GRANT EXECUTE ON  [dbo].[cvo_bo_to_alloc_rx] TO [public]
GO
