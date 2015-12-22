SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_mfg_plan] @asmno varchar(30),  @loc varchar(10), @qty float, 
 @discrete char(1), @eff_date datetime AS 
BEGIN

declare @cnt int, @cnt2 int, @rcnt int, @lp int, @ln int, @lev int,
  @reqasm varchar(30), @seq varchar(4),
  @tqty decimal(20,8), @costpct decimal(20,8),
  @reqqty decimal(20,8), @schqty decimal(20,8),
  @sortseq varchar(3000), @pqty decimal(20,8),
  @parent int, @xlp int,
  @im_status char(1),
  @max_operstep int, @op_seq_factor int,
  @alphabet varchar(26)

select @tqty=Round( @qty, 8 ),
  @reqasm=@asmno, @reqqty=@tqty,  @sortseq='',  @pqty=1, @lev=0, @parent=0,
  @alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

Create Table #tprod ( 
  row_id int identity(1,1), level_no int, line_no int, 
  seq_no varchar(6) NULL, part_no varchar(30),
  location varchar(10), description varchar(255) NULL, 
  plan_qty decimal(20,8), used_qty decimal(20,8), attrib decimal(20,8), 
  uom char(2), conv_factor decimal(20,8), who varchar(255) NULL, 
  note varchar(255) NULL, lb_tracking char(1), 
  bench_stock char(1), status char(1), constrain char(1),
  req_asm varchar(30), req_qty decimal(20,8), plan_pcs decimal(20,8),
  cost_pct decimal(20,8) NULL, direction int NULL, 
  p_qty decimal(20,8) NULL, sortseq varchar(3000) NULL, p_row int, 
  p_pcs decimal(20,8) NULL, pool_qty decimal(20,8) NULL,
  active char(1) NULL, eff_date datetime NULL,
  fixed char(1) NULL)	-- rev 1

create index #tpa on #tprod(constrain)

Create Table #tprod2 (
  row_id int, line_no int identity(1,1), level_no int, 
  seq_no varchar(6) NULL, part_no varchar(30),
  location varchar(10), description varchar(255) NULL, 
  plan_qty decimal(20,8), used_qty decimal(20,8), attrib decimal(20,8), 
  uom char(2), conv_factor decimal(20,8), who varchar(255) NULL, 
  note varchar(255) NULL, lb_tracking char(1), 
  bench_stock char(1), status char(1), constrain char(1),
  req_asm varchar(30), req_qty decimal(20,8), plan_pcs decimal(20,8),
  cost_pct decimal(20,8) NULL, direction int NULL, 
  p_qty decimal(20,8) NULL, sortseq varchar(3000) NULL, p_row int, 
  p_pcs decimal(20,8) NULL, pool_qty decimal(20,8) NULL,
  active char(1) NULL, eff_date datetime NULL,
  fixed char(1) NULL) -- rev 1


Create Table #tprod3 ( 
  row_id int, line_no int identity(1,1), level_no int, oper_step int default(0),
  seq_no varchar(6) NULL, part_no varchar(30),
  location varchar(10), description varchar(255) NULL, 
  plan_qty decimal(20,8), used_qty decimal(20,8), attrib decimal(20,8), 
  uom char(2), conv_factor decimal(20,8), who varchar(255) NULL, 
  note varchar(255) NULL, lb_tracking char(1), 
  bench_stock char(1), status char(1), constrain char(1),
  req_asm varchar(30), req_qty decimal(20,8), plan_pcs decimal(20,8),
  cost_pct decimal(20,8) NULL, direction int NULL, 
  p_qty decimal(20,8) NULL, sortseq varchar(3000) NULL, 
  p_row int, p_line int, p_type char(1) NULL, 
  p_pcs decimal(20,8) NULL, pool_qty decimal(20,8) NULL,
  active char(1) NULL, eff_date datetime NULL,
  fixed char(1) NULL,
  oper_seq varchar(2) NULL,
  line_cnt int NULL,
  line_seq int NULL  )	-- rev 1

create index #tp3a on #tprod3(direction,plan_pcs,line_no)
create index #tp3b on #tprod3(oper_step, constrain, line_no)

select @im_status = isnull((select status 
from inv_master (nolock)
where part_no = @asmno),'')

insert #tprod ( line_no, level_no, seq_no , part_no , location , description , 
  plan_qty , used_qty , attrib , uom , conv_factor , who , 
  note , lb_tracking , bench_stock , status , constrain ,
  req_asm , req_qty, plan_pcs, cost_pct, direction, 
  p_qty, sortseq, p_row, p_pcs, pool_qty,
  active, eff_date, fixed )
select 1, -1, '', i.part_no, @loc, i.description, @tqty, 0, 0, i.uom, 1.0,
  user_name(), null, i.lb_tracking, 'N',
  'N', 'N', @reqasm, @reqqty, @tqty, 100, 1, 
  @pqty, @sortseq, 0, 1, 0, 'A', null, 'N'	-- rev 1, 2
from inv_master i
where @asmno=i.part_no

insert #tprod ( line_no, level_no, seq_no , part_no , location , description , 
  plan_qty , used_qty , attrib , uom , conv_factor , who , 
  note , lb_tracking , bench_stock , status , constrain ,
  req_asm , req_qty, plan_pcs, 
  cost_pct, direction, p_qty, sortseq, p_row, p_pcs, pool_qty,
  active, eff_date, fixed )	-- rev 1
select 0, -1, w.seq_no, w.part_no, @loc, i.description, (w.qty * @tqty), 0,
  w.attrib, w.uom, w.conv_factor, user_name(), null, i.lb_tracking, bench_stock,
  'N', constrain, @reqasm, @reqqty, (w.plan_pcs * @tqty), 
  w.cost_pct, 1, (w.qty * @pqty), @sortseq, 0, 1, w.pool_qty,
  w.active, w.eff_date, 'N'
from what_part w, inv_master i
where @asmno=w.asm_no and  w.part_no=i.part_no and w.active = 'M' and fixed != 'Y'and 
 ( w.location = @loc OR w.location = 'ALL' )

 insert #tprod ( line_no, level_no, seq_no , part_no ,
		 location , description , 
	plan_qty , used_qty , attrib , uom , conv_factor , who , 
	 note , lb_tracking , bench_stock , status , constrain ,
	 req_asm , req_qty, plan_pcs, 
	 cost_pct, direction, p_qty, sortseq, p_row, p_pcs, pool_qty,
	 active, eff_date, fixed )	-- rev 1
 select 0, -1, @seq, w.part_no,
	 @loc, i.description, (w.qty), 0,
	 w.attrib, w.uom, w.conv_factor,
	 user_name(), null, i.lb_tracking, bench_stock,
	 'N', constrain, @reqasm, @reqqty, (w.plan_pcs * @tqty), 
	 w.cost_pct, 1, w.qty, @sortseq, 0, w.plan_pcs, w.pool_qty,	-- rev 1
	 w.active, w.eff_date, 'Y'
 from what_part w, inv_master i
 where @asmno=w.asm_no and 
	 w.part_no=i.part_no and w.active = 'M' and fixed = 'Y' and 
	 ( w.location = @loc OR w.location = 'ALL' )


select @costpct=100 - (sum(cost_pct) - 100) from #tprod
update #tprod set cost_pct=@costpct where line_no=1
update #tprod set line_no=row_id where line_no=0


select @cnt=1, @seq=' ', @lp=1, @rcnt=0
select @cnt2=max(line_no) from #tprod
while @lp > 0 
BEGIN 
 select @rcnt=@rcnt + count(*) 
 from what_part, inv_master i
 where @asmno=what_part.asm_no and 
 what_part.part_no=i.part_no and

(what_part.active = 'A' OR
( what_part.active = 'B' and @eff_date < what_part.eff_date)
 or (what_part.active = 'U' and @eff_date >= what_part.eff_date) ) and 
	 ( what_part.location = @loc OR what_part.location = 'ALL' )
 while @cnt <= @rcnt 


 BEGIN
 set rowcount 1
 select @seq=seq_no
 from what_part, inv_master i
 where @asmno=what_part.asm_no and 
 what_part.part_no=i.part_no and
 seq_no > @seq and 
 
(what_part.active = 'A' OR 
(what_part.active = 'B' and @eff_date < what_part.eff_date) or 
( what_part.active = 'U' and @eff_date >= what_part.eff_date)) and 
 ( what_part.location = @loc OR what_part.location = 'ALL' )
 order by seq_no
 set rowcount 0

 insert #tprod ( line_no, level_no, seq_no , part_no ,location , description , 
	 plan_qty , used_qty , attrib , uom , conv_factor , who , 
	 note , lb_tracking , bench_stock , status , constrain ,
	 req_asm , req_qty, plan_pcs, cost_pct, direction, 
	 p_qty, sortseq, p_row, p_pcs, pool_qty,
	 active, eff_date, fixed )	-- rev 1
 select (@cnt+@cnt2), @lev, @seq, w.part_no,
	 @loc, i.description, (w.qty * @tqty), 0,
	 w.attrib, w.uom, w.conv_factor,
	 user_name(), null, i.lb_tracking, bench_stock,
	 'N', constrain, @reqasm, @reqqty, (w.plan_pcs * @tqty), 0, -1,
	 (w.qty * @pqty), @sortseq+@seq+replicate(' ',5-datalength(@seq))+'.', @parent, (w.plan_pcs * @pqty), w.pool_qty,
	 w.active, w.eff_date, 'N'
 from what_part w, inv_master i
 where @asmno=w.asm_no and @seq=seq_no and 
	 w.part_no=i.part_no and
	 (w.active = 'A' or
	( w.active = 'B' and @eff_date < w.eff_date )
	or (w.active = 'U' and @eff_date >= w.eff_date)) 
	and fixed != 'Y' and 
	( w.location = @loc OR w.location = 'ALL' )

 insert #tprod ( line_no, level_no, seq_no , part_no ,location , description , 
	 plan_qty , used_qty , attrib , uom , conv_factor , who , 
	 note , lb_tracking , bench_stock , status , constrain ,
	 req_asm , req_qty, plan_pcs, cost_pct, direction,
	 p_qty, sortseq, p_row, p_pcs, pool_qty,
	 active, eff_date, fixed )	--rev 1
 select (@cnt+@cnt2), @lev, @seq, w.part_no,
	 @loc, i.description, (w.qty), 0,
	 w.attrib, w.uom, w.conv_factor,
	 user_name(), null, i.lb_tracking, bench_stock,
	 'N', constrain, @reqasm, @reqqty, (w.plan_pcs * @tqty), 0, -1,
	 0, @sortseq+@seq+replicate(' ',5-datalength(@seq))+'.', @parent, w.plan_pcs, w.pool_qty,	-- rev 1
	 w.active, w.eff_date, 'Y'				-- rev 1
 from what_part w, inv_master i
 where @asmno=w.asm_no and @seq=seq_no and 
	( w.part_no=i.part_no and
	( w.active = 'A' or
	( w.active = 'B' and @eff_date < w.eff_date )
	or (w.active = 'U' and @eff_date >= w.eff_date ))
	 )
	and fixed = 'Y' and 
	( w.location = @loc OR w.location = 'ALL' )

 select @cnt=@cnt + 1
 END
 select @lp=isnull( (select min(row_id) from #tprod where constrain='Y'), 0 )
 select @seq=' ', @ln=line_no, @asmno=part_no, @lev=level_no+1,
 @tqty=plan_qty, @pqty=p_qty, @sortseq=sortseq, @parent=row_id 
 from #tprod where row_id = @lp
 update #tprod set constrain='C' where constrain='Y' and row_id = @lp
END

SELECT	T.line_no,RG.resource_part_no part_no,RG.run_factor,RG.use_order
INTO	#resource_group
FROM	#tprod T,
	dbo.resource_group RG (NOLOCK),
	dbo.inv_list IL (NOLOCK)
WHERE	RG.group_part_no = T.part_no
AND	IL.location = T.location
AND	IL.part_no = RG.resource_part_no

-- Remove all that are have a higher use_order
DELETE #resource_group
FROM #resource_group RG1
WHERE EXISTS(	SELECT *
		FROM #resource_group RG2
		WHERE RG2.line_no = RG1.line_no
		AND RG2.use_order < RG1.use_order)
	
UPDATE	#tprod
SET	part_no = RG.part_no, 	plan_qty = plan_qty * RG.run_factor,
	description = IM.description
FROM	#tprod T,
	#resource_group RG,
	dbo.inv_master IM (NOLOCK)
WHERE	RG.line_no = T.line_no
AND	IM.part_no = RG.part_no

DROP TABLE #resource_group			

if @discrete = 'D'
Begin
 update #tprod set used_qty=plan_qty
End
insert #tprod2
 ( row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, p_pcs, pool_qty,
 active, eff_date, fixed )	-- rev 1
select row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, p_pcs, pool_qty,
 active, eff_date, fixed
from #tprod
order by level_no,p_row,sortseq

insert #tprod2
 ( row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, p_pcs, pool_qty,
 active, eff_date, fixed )	-- rev 1
select row_id, '****', part_no, level_no+1,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, 'Y',
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, row_id, p_pcs, pool_qty,
 active, eff_date, fixed
from #tprod
where constrain='C'

if @im_status = 'H'  -- make/routed finished good
begin
insert #tprod3
 ( row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, p_line, p_type, p_pcs, pool_qty,
 active, eff_date, fixed )	-- rev 1
select row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, 0, '', p_pcs, pool_qty,
 active, eff_date, fixed
from #tprod2
order by sortseq, level_no
end
else
begin
insert #tprod3
 ( row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, p_line, p_type, p_pcs, pool_qty,
 active, eff_date, fixed )	-- rev 1
select row_id, seq_no, part_no, level_no,
 location, description, 
 plan_qty, used_qty, attrib, 
 uom, conv_factor, who, 
 note, lb_tracking, 
 bench_stock, status, constrain,
 req_asm, req_qty, plan_pcs,
 cost_pct, direction, p_qty, sortseq, p_row, 0, '', p_pcs, pool_qty,
 active, eff_date, fixed
from #tprod2
order by level_no,p_row,sortseq
end


select @xlp=isnull( (select min(row_id) from #tprod3 where constrain='C'), 0)
while @xlp > 0 begin
 select @lp=line_no from #tprod3 where row_id=@xlp and constrain='C'
 update #tprod3 set p_line=@lp where p_row=@xlp
 select @xlp=isnull( (select min(row_id) from #tprod3 
 where constrain='C' and row_id>@xlp), 0)
end
update #tprod3 set constrain='C' where constrain='Y'
update #tprod3 set p_type=i.status
from inv_master i, #tprod3
where #tprod3.part_no=i.part_no

update #tprod3 set p_type='C' where constrain='C'
update #tprod3 set p_type= 
 CASE WHEN p_type<'N' and constrain<>'C' THEN 'M'
 WHEN p_type<'N' and constrain='C' THEN 'C'
 WHEN p_type>'M' and p_type<'R' THEN 'P'
 WHEN p_type='R' THEN 'R' 
 ELSE 'P'
 END

if @im_status = 'H'
begin
  delete from #tprod3
  where constrain = 'C' and seq_no <> '****'

  if exists (select 1 from #tprod3 where seq_no = '****')
  begin
    update p
    set oper_step = 
      (isnull((select count(*) from #tprod3 p1 where p1.line_no < p.line_no  and plan_pcs > 0 and direction = -1),1) + 1)
    from #tprod3 p
    where direction < 0

    update p
    set oper_seq = 
      case when oper_step < 10 then '0' + convert(char(1),oper_step)
        when oper_step < 100 then convert(char(2),oper_step)
        else substring(@alphabet,(floor((oper_step - 100)/10) +1),1) + 
          convert(varchar(1),oper_step - (floor((oper_step)/10) * 10)) end,
      line_cnt = isnull((select count(*) from #tprod3 p1 where p1.constrain != 'C' and p1.oper_step = p.oper_step ),0),
      line_seq = isnull((select count(*) from #tprod3 p1 where p1.line_no <= p.line_no and p1.constrain != 'C' 
        and p1.oper_step = p.oper_step ),0)
    from #tprod3 p

    update p
    set line_seq = 
      case when line_cnt < 10 then line_seq * 10
        when floor(100/(line_cnt+1)) > 0 then line_seq * floor(100/(line_cnt+1))
        else line_seq end
    from #tprod3 p

    update p
    set seq_no = 
      case when p.seq_no = '' or p.seq_no = '****' then p.seq_no 
      else oper_seq + 
      case when line_seq < 10 then '0' + convert(char(1),line_seq)
        when line_seq < 100 then convert(char(2),line_seq)
        else substring(@alphabet,(floor((line_seq - 100)/10) +1),1) + 
          convert(varchar(1),line_seq - (floor((line_seq)/10) * 10)) end
      end
    from #tprod3 p
  end

  select line_no, seq_no,
    part_no,
    location, description, plan_qty,
    used_qty, attrib, uom,
    conv_factor,  case when datalength(who) > 20 then case charindex('\',who) when 0 then left(who,20) else substring(who,charindex('\',who) +1, datalength(who)) end 
    else who end, note,
    lb_tracking, bench_stock, status,
    constrain, req_asm, req_qty, 
    isnull(plan_pcs,0), cost_pct, direction, p_qty, 
    level_no, line_no, p_type, isnull(p_pcs,0), pool_qty,
    active, eff_date, fixed	-- rev 1
  from #tprod3 
  order by 1
end
else
begin
  select line_no, seq_no, part_no,
    location, description, plan_qty,
    used_qty, attrib, uom,
    conv_factor, case when datalength(who) > 20 then case charindex('\',who) when 0 then left(who,20) else substring(who,charindex('\',who) +1, datalength(who)) end 
    else who end, note,
    lb_tracking, bench_stock, status,
    constrain, req_asm, req_qty, 
    isnull(plan_pcs,0), cost_pct, direction, p_qty, 
    level_no, p_line, p_type, isnull(p_pcs,0), pool_qty,
    active, eff_date, fixed	-- rev 1
  from #tprod3
  order by p_line, seq_no
end

return @cnt
END
GO
GRANT EXECUTE ON  [dbo].[fs_mfg_plan] TO [public]
GO
