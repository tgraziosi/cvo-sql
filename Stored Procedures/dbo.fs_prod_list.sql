SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_prod_list] @prodno int , @prodext int  AS 
BEGIN

declare @cnt int, @rcnt int, @seq varchar(4), @lp int
declare @asmno varchar(30), @qty money
declare	@schqty money, @loc varchar(10), @ln int, @stat char(1)
declare @costpct decimal(20,8)
select @cnt=1, @seq=' ', @lp=1, @rcnt=0
select @asmno=part_no, @qty=qty, @loc=location, @schqty=qty_scheduled, @stat=status
	from produce_all p
	where 	prod_no = @prodno and prod_ext=@prodext
if @qty = 0
BEGIN
	select @qty=@schqty
END
Create Table #tprod
      ( line_no int identity(1,1), seq_no varchar(6) NULL, part_no varchar(30),
        location varchar(10), description varchar(255) NULL, 
        plan_qty decimal(20,8), used_qty decimal(20,8), attrib decimal(20,8), 
        uom char(2), conv_factor decimal(20,8), who varchar(20) NULL, 
        note varchar(255) NULL, lb_tracking char(1), 
        bench_stock char(1), status char(1), constrain char(1),
        plan_pcs decimal(20,8),
        cost_pct decimal(20,8) NULL, direction int NULL )

      insert #tprod ( seq_no , part_no ,location , description , 
        plan_qty , used_qty , attrib , uom , conv_factor , who , 
        note , lb_tracking , bench_stock , status , constrain ,
        plan_pcs, cost_pct, direction )
      select '', i.part_no,
             @loc, i.description, @qty, 0,
             0, i.uom, 1.0,
             user_name(), null, i.lb_tracking, 'N',
             'N', 'N', @qty, 100, 1
      from inv_master i
      where @asmno=i.part_no
      insert #tprod ( seq_no , part_no ,location , description , 
        plan_qty , used_qty , attrib , uom , conv_factor , who , 
        note , lb_tracking , bench_stock , status , constrain ,
        plan_pcs, 
        cost_pct, direction )
      select w.seq_no, w.part_no,
             @loc, i.description, (w.qty * @qty), 0,
             w.attrib, w.uom, w.conv_factor,
             user_name(), null, i.lb_tracking, bench_stock,
             'N', constrain, (w.plan_pcs * @qty), 
             w.cost_pct, 1
      from what_part w, inv_master i
      where @asmno=w.asm_no and 
            w.part_no=i.part_no and w.active = 'M' and fixed != 'Y'  and 
	  ( w.location = @loc OR w.location = 'ALL' )
      insert #tprod ( seq_no , part_no ,location , description , 
        plan_qty , used_qty , attrib , uom , conv_factor , who , 
        note , lb_tracking , bench_stock , status , constrain ,
        plan_pcs, 
        cost_pct, direction )
      select @seq, w.part_no,
             @loc, i.description, (w.qty), 0,
             w.attrib, w.uom, w.conv_factor,
             user_name(), null, i.lb_tracking, bench_stock,
             'N', constrain, (w.plan_pcs * @qty), 
             w.cost_pct, 1
      from what_part w, inv_master i
      where @asmno=w.asm_no and 
            w.part_no=i.part_no and w.active = 'M' and fixed = 'Y'  and 
	  ( w.location = @loc OR w.location = 'ALL' )
select @costpct=100 - (sum(cost_pct) - 100) from #tprod
update #tprod set cost_pct=@costpct where line_no=1
select @cnt = max( line_no ) from #tprod
   insert prod_list (prod_no,     prod_ext, line_no,
                     seq_no,      part_no,  location,
                     description, plan_qty, used_qty,
                     attrib,      uom,      conv_factor,
                     who_entered, note,     lb_tracking,
                     bench_stock, status,   constrain,
                     plan_pcs,    pieces,   scrap_pcs,
                     direction,   cost_pct )
         select      @prodno,     @prodext, line_no,
                     seq_no,      part_no,  location,
                     description, plan_qty, used_qty,
                     attrib,      uom,      conv_factor,
                     who,         note,     lb_tracking,
                     bench_stock, status,   constrain,
                     plan_pcs,    0,        0,
                     direction,   cost_pct
         from #tprod

while @lp > 0 
BEGIN 
   select @rcnt=@cnt + count(*) 
   from   what_part
   where  @asmno=what_part.asm_no and
          what_part.active < 'C'  and 
	  ( what_part.location = @loc OR what_part.location = 'ALL' )
select @cnt = @cnt + 1
while @cnt <= @rcnt 
BEGIN
   set rowcount 1
   select @seq=seq_no 
	   from   what_part 
	   where  @asmno=what_part.asm_no and
	          @seq < seq_no and
	          what_part.active < 'C'  and 
		  ( what_part.location = @loc OR what_part.location = 'ALL' )
		  order by seq_no
   set rowcount 0
   insert prod_list (prod_no,     prod_ext, line_no,
                     seq_no,      part_no,  location,
                     description, plan_qty, used_qty,
                     attrib,      uom,      conv_factor,
                     who_entered, note,     lb_tracking,
                     bench_stock, status,   constrain,
                     plan_pcs,    pieces,   scrap_pcs,
                     direction,   cost_pct )
   select @prodno, @prodext,          @cnt, 
          @seq,             what_part.part_no, @loc, 
          '',               what_part.qty,     0,
          what_part.attrib, what_part.uom,     what_part.conv_factor,
          host_name(),      null,              i.lb_tracking, 
          bench_stock,      @stat,             constrain,
          plan_pcs,         0,                 0,
          -1,               0
	   from   what_part, produce_all p, inv_master i
	   where  @asmno=what_part.asm_no and
		  @prodno=p.prod_no and @prodext=p.prod_ext and
        	  @seq=seq_no and what_part.part_no=i.part_no and
	          what_part.active < 'C' and what_part.fixed = 'Y'  and 
		  ( what_part.location = @loc OR what_part.location = 'ALL' )
   insert prod_list (prod_no,prod_ext, line_no,seq_no,part_no,location,description,plan_qty,
	used_qty,attrib,uom,conv_factor,who_entered,note,lb_tracking,bench_stock,
	status,constrain, plan_pcs,    pieces,   scrap_pcs,
        direction,   cost_pct)
   select @prodno, @prodext, @cnt, @seq, what_part.part_no,
          @loc, '', (what_part.qty * @qty), 0,
          what_part.attrib, what_part.uom, what_part.conv_factor,
          user_name(), null, i.lb_tracking, bench_stock,
          @stat, constrain, plan_pcs, 0, 0,
          -1,    0
	   from   what_part, produce_all p, inv_master i
	   where  @asmno=what_part.asm_no and
		  @prodno=p.prod_no and @prodext=p.prod_ext and	          @seq=seq_no and what_part.part_no=i.part_no and
	          what_part.active < 'C' and what_part.fixed != 'Y'  and 
		  ( what_part.location = @loc OR what_part.location = 'ALL' )
   select @cnt=@cnt + 1
END
select @lp=count(*) from prod_list where
	constrain='Y' and @prodno=prod_no and @prodext=prod_ext
select @seq=' ', @ln=line_no, @asmno=part_no, @qty=plan_qty 
	from   prod_list
	where  constrain='Y'and @prodno=prod_list.prod_no and @prodext=prod_ext
delete prod_list where  constrain='Y' and @prodno=prod_no and @prodext=prod_ext and @ln=line_no
END
END
GO
GRANT EXECUTE ON  [dbo].[fs_prod_list] TO [public]
GO
