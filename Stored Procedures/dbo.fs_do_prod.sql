SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_do_prod] @prodno int, @prodext int, @lot varchar(25)='N/A', @bin varchar(12)='N/A', @expdate datetime  AS 
BEGIN

-- mls 4/13/00 SCR 22566 - changed to use last_tran_date from prod_list as apply_date to gl


declare @cnt int, @rcnt int, @seq varchar(4), @lp int, @asmno varchar(30), @qty decimal(20,8),
	@wqty decimal(20,8), @part varchar(30), @conv decimal(20,8), @uom char(2), @schqty money,
	@loc varchar(10), @ln int, @qstatus char(1), @lb char(1), @constrain char(1), @direction int,
	@uqty decimal(20,8), @msg varchar(255),
	@prod_date datetime									-- mls 4/13/00 SCR 22566 

if @expdate is null select @expdate=getdate()

if @expdate < '1/2/1900' select @expdate=getdate()

if exists (select * from prod_list where prod_no = @prodno and prod_ext = @prodext)
BEGIN
	return -1
END

select @cnt=1, @seq='', @lp=1, @rcnt=0


select @asmno=part_no, @qty=qty, @loc=location, @schqty=qty_scheduled, 
	@qstatus=case qc_flag
		when 'Y' then 'R'
		else 'S'
	end,
	@prod_date = isnull(prod_date, getdate())						-- mls 4/13/00 SCR 22566
	from produce_all produce
	where @prodno=produce.prod_no and @prodext=produce.prod_ext


select @wqty=isnull((select sum(cost_pct) from what_part where
	asm_no=@asmno and active='M'),0) 



insert prod_list (   prod_no,       prod_ext,  line_no,
                     seq_no,        part_no,   location,
                     description,   plan_qty,  used_qty,

		     attrib,        uom,       conv_factor,

                     who_entered,   note,      lb_tracking,
                     bench_stock,   status,    constrain,
                     plan_pcs,      pieces,    scrap_pcs,
                     part_type,	    direction, cost_pct, last_tran_date )				-- mls 4/13/00 SCR 22566

	select @prodno, @prodext, @cnt, 
	   '', @asmno, @loc,
          '', @qty, 0,
          1, i.uom, 1,
          p.who_entered, null, i.lb_tracking, 
          'N', 'N', 'N',
          0,0,0,
	 'P', 1, (100 - @wqty), @prod_date							-- mls 4/13/00 SCR 22566
	   from   inv_master i, produce_all p
	   where  p.prod_no=@prodno and p.prod_ext=@prodext and
                  p.part_no=i.part_no and @asmno=i.part_no 
  if @@error != 0
	begin
		return @@error
	end

select @cnt=@cnt+1

if @qty = 0
BEGIN
	select @qty=@schqty
END
while @lp > 0 
BEGIN 
   select @rcnt=@rcnt + count(*) 
   from   what_part
   where  @asmno=what_part.asm_no and

          (what_part.active < 'C' OR what_part.active='M') and 
	  (what_part.location = @loc OR what_part.location = 'ALL')
while @cnt <= ( @rcnt + 1) 
BEGIN
   set rowcount 1
   select @seq=(select min(seq_no)

	   from   what_part 
	   where  @asmno=what_part.asm_no and
	          seq_no > @seq and

	          (what_part.active < 'C' OR what_part.active='M')  and 
		  (what_part.location = @loc OR what_part.location = 'ALL'))
   set rowcount 0
   insert prod_list (prod_no,       prod_ext,  line_no,
                     seq_no,        part_no,   location,
                     description,   plan_qty,
	             used_qty,
                     attrib,        uom,       conv_factor,
                     who_entered,   note,      lb_tracking,
                     bench_stock,   status,    constrain,
                     plan_pcs,      pieces,    scrap_pcs,
		     part_type,	 direction, cost_pct, last_tran_date)				-- mls 4/13/00 SCR 22566

   select @prodno, 0, @cnt, 
          @seq, w.part_no, @loc,
          '', w.qty, 
          CASE i.lb_tracking WHEN 'N' THEN w.qty WHEN 'Y' THEN 0 END,
          w.attrib, w.uom, w.conv_factor,
          produce.who_entered, null, i.lb_tracking, 
          bench_stock, 'N', constrain,
          0,0,0,
 	  case active when 'M' then 'P' else case i.status when 'R' then 'R' else 'P' end end, -- mls 10/16/09
	  CASE active WHEN 'M' THEN 1 ELSE -1 END,
	  CASE active WHEN 'M' THEN w.cost_pct ELSE 0 END, @prod_date				-- mls 4/13/00 SCR 22566
	   from   what_part w, produce_all produce, inventory i
	   where  @asmno=w.asm_no and i.location=@loc and
                  @prodno=produce.prod_no and @prodext=produce.prod_ext and
        	  @seq=seq_no and w.part_no=i.part_no and

	          (w.active < 'C' OR w.active='M') and

		  w.fixed = 'Y'  and 
	 	  ( w.location = @loc OR w.location = 'ALL' )

  if @@error != 0
	begin
		return @@error
	end

   insert prod_list (prod_no,       prod_ext,  line_no,

                     seq_no,        part_no,   location,
                     description,   plan_qty,  used_qty,
                     attrib,        uom,       conv_factor,
                     who_entered,   note,      lb_tracking,
                     bench_stock,   status,    constrain,

                     plan_pcs,      pieces,    scrap_pcs,
		     part_type,	 direction, cost_pct, last_tran_date)				-- mls 4/13/00 SCR 22566

   select @prodno, 0,@cnt, 
          @seq, w.part_no, @loc, 
          '', (w.qty * @qty), CASE i.lb_tracking WHEN 'N' THEN (w.qty * @qty) WHEN 'Y' THEN 0 END,
          w.attrib, w.uom, w.conv_factor,
          produce.who_entered, null, i.lb_tracking, 
          bench_stock, 'N', constrain,
          0,0,0,
	  case i.status when 'R' then 'R' else 'P' end, -- mls 10/16/09
	  -1, 0, @prod_date				-- mls 4/13/00 SCR 22566
	   from   what_part w, produce_all produce, inventory i
	   where  @asmno=w.asm_no and i.location=@loc and
                  @prodno=produce.prod_no and @prodext=produce.prod_ext and
	          @seq=seq_no and w.part_no=i.part_no and
	          (w.active < 'C' ) and
		   w.fixed != 'Y'  and 

		  ( w.location = @loc OR w.location = 'ALL' )

  if @@error != 0
	begin

		return @@error
	end


   insert prod_list (prod_no,       prod_ext,  line_no,
                     seq_no,        part_no,   location,
                     description,   plan_qty,  used_qty,
                     attrib,        uom,       conv_factor,
                     who_entered,   note,      lb_tracking,
                     bench_stock,   status,    constrain,

                     plan_pcs,      pieces,    scrap_pcs,
		     part_type,	 direction, cost_pct, last_tran_date)				-- mls 4/13/00 SCR 22566

   select @prodno, 0,@cnt, 
          @seq, w.part_no, @loc, 
          '', (w.qty * @qty), 0,
          w.attrib, w.uom, w.conv_factor,

          produce.who_entered, null, i.lb_tracking, 
          bench_stock, 'N', constrain,
          0,0,0,
	  'P', 1 ,w.cost_pct , @prod_date				-- mls 4/13/00 SCR 22566
	   from   what_part w, produce_all produce, inventory i
	   where  
		  @asmno=w.asm_no and i.location=@loc and

                  @prodno=produce.prod_no and @prodext=produce.prod_ext and
	          @seq=seq_no and w.part_no=i.part_no and
	          (w.active='M') and
		   w.fixed != 'Y'  and 
		  ( w.location = @loc OR w.location = 'ALL' )

  if @@error != 0
	begin
		return @@error
	end


if exists (select 1 from prod_list (nolock) 					-- mls 10/20/99 SCR 70 21350
 where prod_no=@prodno and prod_ext=@prodext and line_no=@cnt)			-- mls 10/20/99 SCR 70 21350
begin										-- mls 10/20/99 SCR 70 21350
    select @part = part_no, @conv = conv_factor, 
           @uom = uom, @wqty = plan_qty, @direction = direction, 

           @lb = lb_tracking, @constrain = constrain
           from prod_list

           where prod_no=@prodno and prod_ext=@prodext and line_no=@cnt

    if @lb = 'Y' and @constrain = 'N' and @direction < 0 begin
       exec fs_pick_lot_bin @loc, @part, 'P', @prodno, @prodext, @uom, 
                         @wqty, @conv, @cnt, 'AUTOPICK'
       if isnull( (select count(*) from prod_list
                   where prod_no=@prodno and prod_ext=@prodext and line_no=@cnt and
                         used_qty<plan_qty), 0 ) > 0 begin
          return -4
       end 
    end
end										-- mls 10/20/99 SCR 70 21350


   select @cnt=@cnt + 1
END
select @lp=count(*) from prod_list where
	constrain='Y' and @prodno=prod_no and prod_ext=@prodext

select @seq='', @ln=line_no, @asmno=part_no, @qty=plan_qty 
	from   prod_list
	where  constrain='Y'and 
              @prodno=prod_list.prod_no and prod_ext=@prodext

delete prod_list where  constrain='Y' and 
                 @prodno=prod_no and prod_ext=@prodext and
                 @ln=line_no

  if @@error != 0
	begin
		return @@error
	end

END



if (select count(*) from prod_list where prod_no=@prodno and 

                        prod_ext=@prodext) < 2 begin
	return -3

end

update lot_bin_prod set tran_code=@qstatus where tran_no=@prodno and tran_ext=@prodext
  if @@error != 0
	begin
		return @@error
	end

update prod_list set status=@qstatus where prod_no=@prodno and prod_ext=@prodext and
	direction=-1
  if @@error != 0
	begin
		return @@error
	end



if (select count(*) from prod_list where prod_no=@prodno and 
   prod_ext=@prodext and direction=1) > 0 begin

														-- mls 7/13/06 SCR 36774
  if exists (select 1 from config (nolock) where flag = 'INV_LOT_BIN' and upper(value_str) = 'YES')		-- mls 12/13/02 SCR 30442
  begin
   INSERT lot_bin_prod (
          location       , part_no        , bin_no         , 
          lot_ser        , tran_code      , tran_no        , 
          tran_ext       , date_tran      , date_expires   , 

          qty            , direction      , cost           , 
          uom            , uom_qty        , conv_factor    , 
          line_no        , who            , qc_flag )								-- mls 2/26/01 SCR 26061
   SELECT x.location,      x.part_no, @bin,
          @lot,		 'P',             p.prod_no,
          p.prod_ext,      p.prod_date,     @expdate,
          x.plan_qty,      1,               0,
          x.uom,           x.plan_qty,      1,

          x.line_no,       p.who_entered  , case when isnull(m.qc_flag,'N') = 'Y' then 'Y' else 'N' end		-- mls 2/26/01 SCR 26061
   FROM produce_all p
 join prod_list x (nolock) on p.prod_no=x.prod_no and p.prod_ext=x.prod_ext and x.direction=1 and x.lb_tracking='Y'
 left outer join inv_master m (nolock) on m.part_no = x.part_no						-- mls 2/26/01 SCR 26061
 WHERE p.prod_no=@prodno and p.prod_ext=@prodext 
         
	 
   if @@error != 0
	begin
		return @@error
	end
  end

   UPDATE prod_list set used_qty=plan_qty									-- mls 2/26/01 SCR 26061
   WHERE  prod_no=@prodno and prod_ext=@prodext and direction=1
   if @@error != 0
	begin
		return @@error
	end													


   UPDATE prod_list set status=@qstatus										-- mls 2/26/01 SCR 26061 start
   WHERE  prod_no=@prodno and prod_ext=@prodext and direction=1
   if @@error != 0
	begin
		return @@error
	end													-- mls 2/26/01 SCR 26061 end


end

UPDATE produce_all SET 
	status=@qstatus 
	WHERE prod_no=@prodno and prod_ext=@prodext
  if @@error != 0
	begin
		return @@error
	end

return 1

END
GO
GRANT EXECUTE ON  [dbo].[fs_do_prod] TO [public]
GO
