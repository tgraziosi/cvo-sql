SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_graph_ord] @ord int  AS

declare @ext int, @stat char(1), @stat2 char(1)
select @ext=max(ext) from orders_all where order_no=@ord

create table #tlist
	( location varchar(10), part_no varchar(30), description varchar(45) NULL, 
          uom char(2) NULL, need_qty money, shipped money NULL, 
          demand_source_no varchar(20), demand_date datetime, date_shipped datetime NULL )
create table #tdepends
	( location varchar(10), part_no varchar(30), description varchar(45) NULL, 
          uom char(2) NULL, avail_date datetime NULL, demand_date datetime, 
          avail_source varchar(20), qty money, need_qty money, 
          priority int, order_no int, order_ext int, status char(1) )
if @ext is null
begin
select location, part_no, description, 
       uom, max(avail_date), demand_date, 
       avail_source, sum(qty), need_qty, 
       order_no, order_ext, status 
from #tdepends
group by location, part_no, description, uom, demand_date, avail_source, 
         need_qty, order_no, order_ext, status
order by location, part_no, avail_source
   return
end
select @stat2=status from orders_all where order_no=@ord and ext=@ext
select @stat=@stat2
if @stat2<'V'
Begin
   select @stat = 'S'
End
if @stat2<'R'
Begin
   select @stat = 'N'
End
if @stat2<'N'
Begin
   select @stat = 'H'
End
insert #tlist 
select l.location, l.part_no, substring(l.description,1,45), i.uom,
       sum(l.ordered * l.conv_factor), sum(l.shipped * l.conv_factor),
       convert(varchar(20), @ord), o.sch_ship_date, o.date_shipped
from  inv_master i, ord_list l, orders_all o
where i.part_no = l.part_no AND
      o.order_no = l.order_no AND o.ext = l.order_ext AND
      l.order_no = @ord AND l.order_ext = @ext
group by l.location, l.part_no, substring(l.description,1,45), 
         i.uom, o.sch_ship_date, o.date_shipped
if @stat='S'
 Begin
   insert #tdepends 
   select location, part_no, description, uom, date_shipped, demand_date,
          'N/A', shipped, need_qty, 0, @ord, @ext, @stat
   from  #tlist 
 End
Else
 Begin
   insert #tdepends 
   select  t.location, t.part_no, t.description, t.uom, d.avail_date, t.demand_date,
           d.avail_source, d.qty, 
           t.need_qty, 0, @ord, @ext, @stat
   from   resource_depends d, #tlist t
   where  d.part_no=t.part_no and d.location=t.location and d.qty>0 and
          d.demand_source='C' and d.demand_source_no = t.demand_source_no
   update #tdepends set avail_source='Inv'
   where  avail_source='I'
   update #tdepends set avail_source='Sch'
   where  avail_source='R'
   update #tdepends set avail_source='Sch'
   where  avail_source='S'
   update #tlist
   set    shipped=( select sum(qty)
 	  from   #tdepends d
 	  where  d.location = #tlist.location and d.part_no = #tlist.part_no )
   update #tlist set shipped=0
   where shipped is null
   insert #tdepends 
   select location, part_no, description, uom, null, demand_date,
          'Unplanned', ( need_qty - shipped ), need_qty, 0, @ord, @ext, @stat
   from   #tlist 
   where  shipped < need_qty
 End
select location, part_no, description, 
       uom, max(avail_date), demand_date, 
       avail_source, sum(qty), need_qty, 
       order_no, order_ext, status 
from  #tdepends
group by location, part_no, description, uom, demand_date, avail_source, 
         need_qty, order_no, order_ext, status
order by location, part_no, avail_source

GO
GRANT EXECUTE ON  [dbo].[fs_graph_ord] TO [public]
GO
