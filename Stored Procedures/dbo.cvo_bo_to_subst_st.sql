SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_bo_to_subst_st] 
as 

-- ST backorders to substitute
-- exec cvo_bo_to_subst_st
-- 6/15/2015 - tag - update to look at only stock with min 10 ATP

set nocount ON
SET ANSI_WARNINGS off

declare @today datetime
select @today = dateadd(dd, datediff(dd,0,getdate()), 0)


IF OBJECT_ID('tempdb..#orders') IS NOT NULL DROP TABLE #orders
create table #orders
(
id int identity (1,1),
order_no int,
ext int,
line_no int,
user_category varchar(10),
date_entered datetime,
brand varchar(20),
style varchar(20),
color varchar(20),
size float,
part_no varchar(40),
type_code varchar(10),
location varchar(12),
open_qty int,
qty_to_sub int,
sub_part_no varchar(40),
qty_avl_to_sub int,
nextpoduedate varchar(12)
)

insert #orders
select o.order_no, o.ext, ol.line_no, o.user_category, o.date_entered, 
i.category brand, ia.field_2 style, ia.category_5 color, 
ia.field_17 size, ol.part_no, i.type_code, ol.location, ol.ordered-ol.shipped open_qty
, -1 as qty_to_sub, space(40) as sub_part_no, 0 as qty_avl_to_sub, space(12) as nextpoduedate
-- into #orders
from orders o (nolock)
inner join ord_list ol (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
inner join cvo_ord_list col (nolock) on col.order_no = ol.order_no and col.order_ext = ol.order_ext and col.line_no = ol.line_no
inner join inv_master i (nolock) on ol.part_no = i.part_no
inner join inv_master_add ia (nolock) on ol.part_no = ia.part_no
inner join dbo.cvo_item_avail_vw  iav (nolock) on 
	ol.part_no =  iav.part_no and o.location = iav.location
join cvo_armaster_all car (nolock) on car.customer_code = o.cust_code and car.ship_to = o.ship_to
left outer join cvo_hard_allocated_vw alloc (nolock) 
	on alloc.order_no = o.order_no 
	and alloc.order_ext = o.ext
	and alloc.line_no = ol.line_no
	and alloc.order_type = 'S'
where o.status = 'n' 
and ia.field_26 <= @today
and isnull(iav.qty_avl,0) <= 0 
and isnull(car.allow_substitutes,0) = 1
and o.type = 'i' 
-- and o.who_entered in ('backordr','outofstock')
and o.sch_ship_date < @today
and ol.ordered > (ol.shipped + isnull(alloc.qty,0))
and i.type_code in ('frame','sun')
and o.user_category like 'st%' and o.user_category <> 'st-tr'
and col.is_customized = 'n'
and ol.part_type = 'p'

create index idx_t on #orders (order_no, ext, location, part_no) include (open_qty, qty_to_sub)

-- get parts and qtys available as substitutes

IF OBJECT_ID('tempdb..#subs') IS NOT NULL DROP TABLE #subs

select distinct iav.brand, iav.style,  ia.category_5 color, ia.field_17 size, 
	            iav.part_no sub_part_no, iav.location, iav.sof qty_avl_to_sub
into #subs
from #orders 
inner join dbo.cvo_item_avail_vw iav (nolock) on #orders.brand = iav.Brand  and #orders.style = iav.style
	AND iav.location = #orders.location
inner join inv_master_add ia on ia.part_no = iav.part_no
where 1=1
and ia.field_26 <= @today
-- and (av4end > 0 and av8end > 0 and av12end > 0 and av16end > 0 and av20end > 0)
-- and sa_allocated > 0 -- sa_allocated is qty avl now
-- 061515 - min 10 atp required
AND iav.future_ord_qty = 0
AND iav.qty_avl >= 10 -- sa_allocated is qty avl now
and iav.type_code IN ('frame','sun') 
-- and iav.location = #orders.location
and #orders.part_no <> iav.part_no

-- select * from dpr_report where style = 'brynn'

-- select * from #orders order by brand, style, part_no
-- select * from #subs order by brand, style, sub_part_no

declare @loc varchar(12), @brand varchar(20), @style varchar(20), @part varchar(40), 
		@qty_avl_to_sub int, @line_no int, @order int, @ext int, @open_qty int, @qty_to_sub int, 
		@nextpoduedate varchar(12), @sub_part_no varchar(40)
		, @color varchar(20), @size float, @id int

select @loc = min(location) From #orders 
-- select @loc
select @part = min(part_no) from #orders where location = @loc 
select @brand = brand, @style = style, @size = size, @color = color 
		from #orders where location = @loc and part_no = @part

select @id = min(id) from #orders where @part = part_no and @loc = location

	-- check for a sub on size first
select @sub_part_no = '', @qty_avl_to_sub = 0
select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color = color and @size <> size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc
	-- check for a sub on color with same size
if @sub_part_no = '' 
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color <> color and @size = size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc
	-- check for a sub on anything within the style
if @sub_part_no = '' 
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color <> color and @size <> size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc

update #orders set nextpoduedate = (select nextpoduedate
					from cvo_item_avail_vw where location = @loc and part_no = @part),
					sub_part_no = @sub_part_no,
					qty_avl_to_sub = @qty_avl_to_sub  
					where #orders.part_no = @part and #orders.location = @loc

While @loc is not null
begin
			
	while @part is not null 
	begin

	 while @sub_part_no <> '' and @qty_avl_to_sub > 0 and @id is not null
	 	begin
			select @open_qty = open_qty from #orders where id = @id
			select @qty_to_sub = case when isnull(@qty_avl_to_sub,0) >= @open_qty then @open_qty else @qty_avl_to_sub end
			update #orders set #orders.qty_to_sub = @qty_to_sub, #orders.qty_avl_to_sub = @qty_avl_to_sub
				where id = @id
			select @qty_avl_to_sub = @qty_avl_to_sub - @qty_to_sub
			select @id = min(id) from #orders where location = @loc and part_no = @part and id > @id
	 end -- do we have anything to sub?

	 update #subs set qty_avl_to_sub = @qty_avl_to_sub where sub_part_no = @sub_part_no and location = @loc

	 select @part = min(part_no) From #orders where location =  @loc and part_no > @part

	 select @brand = brand, @style = style, @size = size, @color = color 
		from #orders where location = @loc and part_no = @part
	 select @id = min(id) from #orders where @part = part_no and @loc = location
	-- check for a sub on size first
	 select @sub_part_no = '', @qty_avl_to_sub = 0
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color = color and @size <> size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc
	-- check for a sub on color with same size
	 if @sub_part_no = '' 
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color <> color and @size = size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc
	-- check for a sub on anything within the style
	 if @sub_part_no = '' 
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color <> color and @size <> size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc

	 update #orders set nextpoduedate = (select nextpoduedate
					from cvo_item_avail_vw where location = @loc and part_no = @part),
					sub_part_no = @sub_part_no,
					qty_avl_to_sub = @qty_avl_to_sub  
					where #orders.part_no = @part and #orders.location = @loc
	
	 
	end -- part

	select @loc = min(location) From #orders where location > @loc
	select @part = min(part_no) from #orders where location = @loc 
	select @brand = brand, @style = style, @size = size, @color = color 
		from #orders where location = @loc and part_no = @part
	select @sub_part_no = '', @qty_avl_to_sub = 0
	select @id = min(id) from #orders where @part = part_no and @loc = location
	 -- check for a sub on size first
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color = color and @size <> size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc
	-- check for a sub on color with same size
	 if @sub_part_no = '' 
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color <> color and @size = size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc
	-- check for a sub on anything within the style
	 if @sub_part_no = '' 
	 select top 1 @sub_part_no = isnull(sub_part_no,''), @qty_avl_to_sub = isnull(qty_avl_to_sub,0)
		from #subs where location = @loc and brand = @brand and style = @style and @color <> color and @size <> size 
		and sub_part_no <> @part
		order by qty_avl_to_sub desc

 	 update #orders set nextpoduedate = (select nextpoduedate
					from cvo_item_avail_vw where location = @loc and part_no = @part),
					sub_part_no = @sub_part_no,
					qty_avl_to_sub = @qty_avl_to_sub  
					where #orders.part_no = @part and #orders.location = @loc
					

end -- location


--select #qty.*,#orders.order_no, #orders.ext, #orders.open_qty, #orders.qty_to_sub from #qty
--join #orders on #qty.part_no = #orders.part_no and #qty.location = #orders.location

select brand, style, 
-- color_code, a_size, 
part_no, type_code, order_no, ext, 
-- line_no, 
user_category, date_entered, location, open_qty, sub_part_no, qty_to_sub, 
qty_avl_to_sub, 
isnull(nextpoduedate,'') nextpoduedate
from #orders 
where 1=1
-- and qty_to_sub > 0 
order by part_NO, order_no


GO
GRANT EXECUTE ON  [dbo].[cvo_bo_to_subst_st] TO [public]
GO
