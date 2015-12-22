SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_val_overship_group] @load_no int
AS
create table #temp (
part_no varchar(30) not null,
location varchar(10) not null,
inv_status char(1) not null,
ordered decimal(20,8) not null,
shipped decimal(20,8) not null,
in_stock decimal(20,8) not null)

create table #tempk (
part_no varchar(30) not null,
location varchar(10) not null,
inv_status char(1) not null,
ordered decimal(20,8) not null,
shipped decimal(20,8) not null,
in_stock decimal(20,8) not null)

declare @lm_status char(1)

select @lm_status = status
from load_master_all (nolock)
where load_no = @load_no

insert #temp
select main.part_no,
  main.location,
  main.inv_status,
  sum(main.ordered) ordered,
  sum(main.shipped) shipped,
  i.in_stock + i.hold_xfr +
  isnull((select sum(ol.shipped * ol.conv_factor)
    from ord_list ol (nolock)
    where ol.part_no =  main.part_no and ol.location = main.location and
      ol.status in ('P','Q') and ol.part_type = 'P'),0) +
      isnull((select sum(k2.shipped * k2.qty_per * k2.conv_factor)
    from ord_list_kit k2 (nolock)
    where k2.part_no = main.part_no and k2.location = main.location
      and k2.status IN ('P','Q') and k2.part_type = 'P'),0) +
  case when @lm_status > 'Q' then sum(main.shipped) else 0 end in_stock
from 
  (select ll.load_no, ol.part_no, ol.location, i.status inv_status,			
  ol.ordered, ol.shipped * ol.conv_factor shipped
  from ord_list   ol (nolock),
    inventory_unsecured  i (nolock),
    load_list  ll (nolock)
  where ol.part_no   = i.part_no and ol.location  = i.location
    and ll.order_no  = ol.order_no and ll.order_ext = ol.order_ext
    and ol.part_type = 'P'

  union ALL
  
  select ll.load_no, k.part_no, k.location, i.status inv_status,
    ol.ordered, k.shipped * k.qty_per * k.conv_factor shipped
  from ord_list ol (nolock),
    load_list ll (nolock),
    ord_list_kit k (nolock),
    inventory_unsecured i (nolock)
  where k.order_no   = ol.order_no  and k.order_ext  = ol.order_ext 
    and k.location   = ol.location and ll.order_no  = ol.order_no
    and ll.order_ext = ol.order_ext  and i.part_no = k.part_no
    and i.location = k.location and k.part_type = 'P'
    and ol.part_type = 'C') main,
  inventory_unsecured i (nolock)
  where main.part_no = i.part_no and main.location = i.location and
    main.load_no = @load_no
  group by main.load_no,main.part_no,main.location,main.inv_status,i.in_stock, i.hold_xfr

insert #tempk
select
  wp.part_no,
  t.location,
  i.status,
  sum(t.ordered * wp.qty),
  sum(case when wp.fixed = 'N' then (t.shipped - t.in_stock) * wp.qty 
    else wp.qty end),
  i.in_stock + i.hold_xfr +
  isnull((select sum(ol.shipped * ol.conv_factor)
    from ord_list ol (nolock)
    where ol.part_no =  wp.part_no and ol.location = t.location and
      ol.status in ('P','Q') and ol.part_type = 'P'),0) +
      isnull((select sum(k2.shipped * k2.qty_per * k2.conv_factor)
    from ord_list_kit k2 (nolock)
    where k2.part_no = wp.part_no and k2.location = t.location
      and k2.status IN ('P','Q') and k2.part_type = 'P'),0) +
  case when @lm_status > 'Q' then 
  sum(case when wp.fixed = 'N' then (t.shipped - t.in_stock) * wp.qty 
    else wp.qty end) else 0 end
from #temp t,
  what_part wp (nolock),
  inventory_unsecured i (nolock)
where wp.asm_no      = t.part_no
  and wp.active      < 'C'
  and (wp.location = 'ALL' or wp.location = t.location)
  and t.inv_status       = 'K'
  and t.shipped > t.in_stock   
  and i.part_no = wp.part_no
  and i.location = t.location
group by wp.part_no,t.location,i.status,i.in_stock, i.hold_xfr

update #temp 
set shipped = in_stock
where inv_status = 'K'

insert #temp
select part_no,location,inv_status,ordered,shipped,in_stock
from #tempk

delete from #tempk

insert #tempk
select part_no,location,inv_status,sum(ordered),sum(shipped),in_stock
from #temp
group by part_no, location, inv_status, in_stock

select part_no,location,inv_status,ordered,shipped,in_stock
from #tempk
where shipped > in_stock

drop table #temp
drop table #tempk
GO
GRANT EXECUTE ON  [dbo].[adm_val_overship_group] TO [public]
GO
