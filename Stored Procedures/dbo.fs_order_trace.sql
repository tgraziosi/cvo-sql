SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_order_trace] @ord int, @ext int  AS

set nocount on
declare @x int, @loc varchar(10), @pn varchar(30)
declare @sdate datetime, @stat char(1)
declare @qty money
create table #tdemand
	( parent varchar(30), ilevel int, seq_no varchar(10), part_no varchar(30), 
          location varchar(10), description varchar(45) NULL, qty money, 
          source char(1) NULL, source_no varchar(20) NULL, source_date datetime NULL, 
          order_no int, order_ext int, order_date datetime )
create table #tdepends
	( parent varchar(30), ilevel int, seq_no varchar(10), part_no varchar(30), 
          location varchar(10), description varchar(45) NULL, ordered money, qty money, 
          source char(1) NULL, source_no varchar(20) NULL, source_date datetime NULL, 
          order_no int, order_ext int, order_date datetime )
create table #tord
	( order_no int, order_ext int, part_no varchar(30), location varchar(10), 
          ordered money, status char(1) ) 
create table #tsubs
	( sub_no varchar(20), qty money, fixed char(1), seq_no varchar(10) )
select @ext=0
SELECT @sdate=sch_ship_date,
       @stat=status
FROM   orders_all
WHERE  order_no=@ord and ext=@ext
insert #tord
select distinct @ord, @ext, x.part_no, x.location, x.ordered, 'N'
from ord_list x
where x.order_no=@ord and x.order_ext=@ext
update #tord set ordered=(select sum(ordered) from ord_list
                          where #tord.order_no=ord_list.order_no and
                                #tord.order_ext=ord_list.order_ext and
                                #tord.part_no=ord_list.part_no and
                                #tord.location=ord_list.location
                          group by ord_list.order_no,ord_list.order_ext,
                                ord_list.part_no,ord_list.location)
from ord_list
where #tord.order_no=ord_list.order_no and
      #tord.order_ext=ord_list.order_ext and
      #tord.part_no=ord_list.part_no and
      #tord.location=ord_list.location
select @x = count(*) from #tord where status='N'
WHILE @x > 0 
BEGIN
   set rowcount 1
   SELECT @pn=part_no,
          @qty=ordered,
          @loc=location
   FROM #tord WHERE status='N'
   set rowcount 0
   INSERT #tsubs
   SELECT part_no, qty, fixed, seq_no
   FROM   what_part
   WHERE  asm_no=@pn and active<'B'  and 
	  ( what_part.location = @loc OR what_part.location = 'ALL' )
   UPDATE #tsubs SET qty=(qty * @qty)
   WHERE  fixed='N'
   UPDATE #tsubs SET fixed='N'
   UPDATE #tsubs SET fixed='Y'
   WHERE exists ( select * from what_part where #tsubs.sub_no=what_part.asm_no )
   delete #tsubs 
   WHERE  fixed='N'
   insert #tdemand
   SELECT @pn, 0, '', @pn, @loc, null, @qty, '?', null, null, @ord, @ext, @sdate
   INSERT #tdemand
   SELECT @pn, 1, seq_no, sub_no, @loc, null, qty, '?', null, null, @ord, @ext, @sdate
   FROM   #tsubs
   delete #tsubs
   UPDATE #tord SET status='X'
   WHERE  part_no=@pn
   select @x = count(*) from #tord where status='N'
   
END
UPDATE #tdemand SET description=Substring( i.description,1,45 )
FROM   inv_master i
WHERE  i.part_no=#tdemand.part_no
INSERT #tdepends
SELECT t.parent, t.ilevel, t.seq_no, t.part_no,
       t.location, t.description, t.qty, r.qty,
       r.avail_source, r.avail_source_no, r.avail_date, 
       t.order_no, t.order_ext, t.order_date
FROM   #tdemand t, resource_depends r
WHERE  t.part_no=r.part_no and r.demand_source='C' and
       r.demand_source_no=convert(varchar(20), @ord)
INSERT #tdepends
SELECT t.parent, t.ilevel, t.seq_no, t.part_no,
       t.location, t.description, t.qty, 0,
       'Z', '0', null,
       t.order_no, t.order_ext, t.order_date
FROM   #tdemand t
WHERE  t.ilevel=0 AND NOT EXISTS (select * from #tdepends where #tdepends.part_no=t.part_no and t.ilevel=0)
SELECT parent, ilevel, seq_no, part_no, 
          location, description, ordered, qty, 
          source, source_no, source_date, 
          order_no, order_ext, order_date
FROM #tdepends

ORDER BY parent, ilevel, seq_no

GO
GRANT EXECUTE ON  [dbo].[fs_order_trace] TO [public]
GO
