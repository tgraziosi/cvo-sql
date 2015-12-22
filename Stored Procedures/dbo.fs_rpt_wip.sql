SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_wip] @prodno int, @ext int, @loc varchar(10), 
                 @rptmeth char(1), @costmeth char(1) AS

create table #tprod (
   prod_no int ,
   prod_ext int ,
   prod_part varchar(30) NULL ,
   prod_description varchar(255) NULL ,
   prod_sch_qty decimal(20,8) ,
   prod_qty decimal(20,8)
)
create table #tprod2 (
   prod_no int ,
   prod_ext int ,
   prod_part varchar(30) NULL ,
   prod_description varchar(255) NULL ,
   prod_sch_qty decimal(20,8) ,
   prod_qty decimal(20,8) ,
   part_no varchar(30) ,
   location varchar(10) ,
   description varchar(255) NULL ,
   cost decimal(20,8) ,
   ddolrs decimal(20,8) ,
   odolrs decimal(20,8) ,
   udolrs decimal(20,8) ,
   qty decimal(20,8)
)
insert #tprod
select prod_no, prod_ext, part_no, description, qty_scheduled, qty
from   produce_all
where  status>='P' and status<'R' and
       ( @prodno = 0 or ( prod_no = @prodno and prod_ext = @ext ) ) and
       ( @loc = '%' or location like @loc )
insert #tprod2
select p.prod_no, p.prod_ext, p.prod_part, p.prod_description,
       p.prod_sch_qty, p.prod_qty, l.part_no, l.location, l.description,
       x.cost, x.direct_dolrs, x.ovhd_dolrs, x.util_dolrs,
       x.qty
from #tprod p, prod_list l, prod_list_cost x
where p.prod_no=l.prod_no and p.prod_ext=l.prod_ext and
      l.prod_no=x.prod_no and l.prod_ext=x.prod_ext and
      l.line_no=x.line_no and l.part_no=x.part_no
if @costmeth='S' begin
   update #tprod2
      set #tprod2.cost=i.std_cost, ddolrs=i.std_direct_dolrs,
          odolrs=i.std_ovhd_dolrs, udolrs=i.std_util_dolrs
   from inventory i where
        i.part_no=#tprod2.part_no and 
        i.location=#tprod2.location
end
if @rptmeth = 'D' begin
   select prod_no, prod_ext, prod_part, prod_description,
          prod_sch_qty, prod_qty, part_no, location, description,
          sum(cost * qty), sum(ddolrs * qty) 'direct dolrs', 
          sum(odolrs * qty) 'ovhd dolrs', 
          sum(udolrs * qty) 'utility dolrs', sum(qty), @costmeth
   from #tprod2
   group by prod_no, prod_ext, prod_part, prod_description,
          prod_sch_qty, prod_qty, part_no, location, description
   order by prod_no, prod_ext, prod_part, prod_description,
          prod_sch_qty, prod_qty, part_no, location, description
end
else begin
   select prod_no, prod_ext, prod_part, prod_description,
          prod_sch_qty, prod_qty, '', CASE @loc WHEN '%' THEN '' ELSE @loc END, '',
          sum(cost * qty) 'cost', sum(ddolrs * qty) 'direct dolrs', 
          sum(odolrs * qty) 'ovhd dolrs', 
          sum(udolrs * qty) 'utility dolrs', 0 'qty', @costmeth
   from #tprod2
   group by prod_no, prod_ext, prod_part, prod_description,
          prod_sch_qty, prod_qty
   order by prod_no, prod_ext, prod_part, prod_description,
          prod_sch_qty, prod_qty
end
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_wip] TO [public]
GO
