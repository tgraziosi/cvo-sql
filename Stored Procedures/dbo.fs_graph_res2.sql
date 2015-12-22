SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_graph_res2] @loc varchar(10), @pn1 varchar(30), @pn2 varchar(30), 
                 @bdate datetime, @edate datetime, @type char(1)  AS


create table #tdepends
	( location varchar(10), part_no varchar(30), description varchar(45) NULL, 
          uom char(2) NULL, avail_date datetime, demand_date datetime, 
          demand_source varchar(20), qty money, priority int )
create table #tlist
	( location varchar(10), part_no varchar(30), description varchar(45) NULL, uom char(2) NULL )
insert #tlist select i.location, i.part_no, i.description, i.uom
from inventory i
where i.part_no >= @pn1 and i.part_no<=@pn2 and 
i.location like @loc and i.status='R'
insert #tdepends 
select  d.location, d.part_no, i.description, i.uom, d.avail_date, d.demand_date,
        d.demand_source+convert(varchar(18),d.demand_source_no), qty, 0
from   resource_depends d, inventory i
where   d.part_no=i.part_no and d.location=i.location and i.status='R' and d.qty>0 and
        d.part_no >= @pn1 and d.part_no<=@pn2 and d.location like @loc and 
        d.avail_date>=@bdate and d.avail_date<=@edate
insert #tdepends
select  d.location, d.part_no, i.description, i.uom, d.avail_date, d.avail_date,
        'IDLE', qty, 99
from   resource_avail d, inventory i
where   d.part_no=i.part_no and d.location=i.location and i.status='R' and d.qty>0 and
        d.part_no >= @pn1 and d.part_no<=@pn2 and d.location like @loc and 
        d.avail_date>=@bdate and d.avail_date<=@edate
if @type='I'
begin
   select location, part_no, description, uom, min(avail_date), 
          min(demand_date), demand_source, sum(qty)
   from  #tdepends
   GROUP BY location, part_no, description, uom, demand_source
   order by location, part_no, demand_source
end
if @type='D'
begin
   select location, part_no, description, uom, avail_date, 
          min(demand_date), demand_source, sum(qty)
   from  #tdepends

   GROUP BY location, part_no, description, uom, avail_date, demand_source
   order by location, part_no, demand_source
end

GO
GRANT EXECUTE ON  [dbo].[fs_graph_res2] TO [public]
GO
