SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_expand_plist] @pno int, @pext int, @exlno int  AS 
BEGIN

declare @needqty decimal(20,8), @pqty decimal(20,8)
declare @exseq varchar(4), @seq varchar(4), @cs char(1)
declare @ptype char(1),    @stat char(1),   @loc varchar(10)
declare @expart varchar(30), @part varchar(30)
declare @lno int, @next_lno int, @pline int, @start_lno int
declare @rcnt int, @cnt int, @lp int
declare @msg varchar(255)
DELETE temp_prod_list where prod_no=@pno and prod_ext=@pext
select @expart=part_no,  @exseq=seq_no, @needqty=plan_qty,
       @ptype=part_type, @loc=location, @stat=status,
       @lno=line_no,     @cs=constrain, @pqty=p_qty, @pline=line_no
from prod_list
where prod_no=@pno and prod_ext=@pext and line_no=@exlno







if @stat > 'N' begin
   select @msg = 'Job Not in edit mode.'
   exec fs_sql_log @msg
   return -2
end
select @start_lno=isnull( (select max(line_no)
                          from prod_list 
                          where prod_no=@pno and prod_ext=@pext), 0) + 1
select @next_lno = @start_lno
select @cnt=1, @seq='', @lp=1, @rcnt=0
while @lp > 0 
BEGIN 
   select @seq=isnull( (select min(seq_no)
                        from what_part, inventory
                        where what_part.asm_no=@expart and 
                        what_part.part_no=inventory.part_no and 
                        inventory.location=@loc and
                        what_part.active < 'C'  and 
	  ( what_part.location = @loc OR what_part.location = 'ALL' )), '' )
   while @seq > ''
   BEGIN
      select @next_lno = @next_lno + 1

      set rowcount 0
      INSERT dbo.temp_prod_list (
                 prod_no ,      prod_ext ,   line_no ,
                 seq_no ,       part_no  ,   location ,
                 description ,  plan_qty ,   used_qty ,
                 attrib ,       uom ,        conv_factor ,
                 who_entered ,  note ,       lb_tracking ,
                 bench_stock,   status ,     constrain ,
                 plan_pcs ,     pieces,	     scrap_pcs,
                 part_type,     p_qty,       p_line,
                 p_pcs )
          select @pno,          @pext,                @next_lno,
                 @exseq,        w.part_no,            @loc, 
                 i.description, (w.qty * @needqty),   0,
                 w.attrib,      i.uom,                1.0,
                 user_name(),   null,                 i.lb_tracking, 
                 bench_stock,   @stat,                constrain, 
                 (w.plan_pcs * @pqty),   0,           0,
                 i.status,      (w.qty * @pqty),      @pline,
                 w.plan_pcs
            from what_part w, inv_master i
           where w.asm_no=@expart and @seq=seq_no and 
                 w.part_no=i.part_no and w.active < 'C' and fixed != 'Y'  and 
		 ( w.location = @loc OR w.location = 'ALL' )
      INSERT dbo.temp_prod_list (
                 prod_no ,      prod_ext ,   line_no ,
                 seq_no ,       part_no  ,   location ,
                 description ,  plan_qty ,   used_qty ,
                 attrib ,       uom ,        conv_factor ,
                 who_entered ,  note ,       lb_tracking ,
                 bench_stock,   status ,     constrain ,
                 plan_pcs ,     pieces,	     scrap_pcs,
                 part_type,     p_qty,       p_line,
                 p_pcs )
          select @pno,          @pext,                @next_lno,
                 @exseq,        w.part_no,            @loc, 
                 i.description, w.qty,                0,
                 w.attrib,      i.uom,                1.0,
                 user_name(),   null,                 i.lb_tracking, 
                 bench_stock,   @stat,                constrain, 
                 (w.plan_pcs * @pqty),    0,          0,
                 i.status,      w.qty,                @pline,
                 w.plan_pcs
            from what_part w, inv_master i
           where w.asm_no=@expart and @seq=seq_no and 
                 w.part_no=i.part_no and w.active < 'C' and fixed = 'Y'  and 
		 ( w.location = @loc OR w.location = 'ALL' )
      select @seq=isnull( (select min(seq_no)
                           from what_part, inventory
                           where what_part.asm_no=@expart and 
                           what_part.part_no=inventory.part_no and 
                           inventory.location=@loc and
                           what_part.active < 'C' and seq_no>@seq  and 
	  ( what_part.location = @loc OR what_part.location = 'ALL' )), '' )
   END
   select @lp=isnull( (select min(row_id) from temp_prod_list
                       where prod_no=@pno and prod_ext=@pext and 
                       constrain='Y' and line_no>@lp), 0 )
   select @seq='', @lno=line_no, @expart=part_no, 
          @needqty=plan_qty, @pqty=p_qty, @pline=line_no 
          from temp_prod_list
          where prod_no=@pno and prod_ext=@pext and row_id=@lp
   update temp_prod_list set constrain='C' where constrain='Y' and row_id=@lp
END
select @cnt = count(*) from temp_prod_list
where prod_no=@pno and prod_ext=@pext
if @cnt <= 0 begin
   return -3
end
update temp_prod_list set part_type='M' 
       where prod_no=@pno and prod_ext=@pext and 
             part_type<='M'
update temp_prod_list set part_type='P' 
       where prod_no=@pno and prod_ext=@pext and 
             part_type<>'M' and part_type<>'R'
select @cnt=isnull( (select min(row_id)
                     from temp_prod_list 
                     where prod_no=@pno and prod_ext=@pext and constrain='C'), 0)
while @cnt > 0 begin
   select @next_lno=@next_lno + 1
   INSERT dbo.temp_prod_list (
              prod_no ,      prod_ext ,   line_no ,
              seq_no ,       part_no  ,   location ,
              description ,  plan_qty ,   used_qty ,
              attrib ,       uom ,        conv_factor ,
              who_entered ,  note ,       lb_tracking ,
              bench_stock,   status ,     constrain ,
              plan_pcs ,     pieces,	  scrap_pcs,
              part_type,     p_qty,       p_line,
              p_pcs )
       select 
              prod_no,       prod_ext,    @next_lno,
              '****',        part_no,     location, 
              description,   plan_qty,    used_qty,
              attrib,        uom,         conv_factor,
              who_entered,   null,        lb_tracking, 
              bench_stock,   status,      'Y', 
              plan_pcs,      pieces,      scrap_pcs,
              part_type,     p_qty,       line_no,
              p_pcs
         from dbo.temp_prod_list
        where prod_no=@pno and prod_ext=@pext and row_id=@cnt
   select @cnt=isnull( (select min(row_id)
                        from temp_prod_list 
                        where prod_no=@pno and prod_ext=@pext and constrain='C' and
                        row_id>@cnt), 0)
end
update dbo.temp_prod_list set part_type='C', constrain='C' 
       where constrain='C' or constrain='Y'
INSERT dbo.prod_list (
           prod_no ,      prod_ext ,   line_no ,
           seq_no ,       part_no  ,   location ,
           description ,  plan_qty ,   used_qty ,
           attrib ,       uom ,        conv_factor ,
           who_entered ,  note ,       lb_tracking ,
           bench_stock,   status ,     constrain ,
           plan_pcs ,     pieces,      scrap_pcs,
           part_type,     direction,   cost_pct,
           p_qty,         p_line,      p_pcs )
SELECT     prod_no ,      prod_ext ,   @start_lno ,
           '****' ,       part_no  ,   location ,
           description ,  plan_qty ,   used_qty ,
           attrib ,       uom ,        conv_factor ,
           who_entered ,  note ,       lb_tracking ,
           bench_stock,   status ,     'C' ,
           plan_pcs ,     pieces,      scrap_pcs,
           'C',           -1,          0,
           p_qty,         line_no,     p_pcs
FROM prod_list
WHERE prod_list.prod_no=@pno and prod_list.prod_ext=@pext and prod_list.line_no=@exlno
INSERT dbo.prod_list (
           prod_no ,      prod_ext ,   line_no ,
           seq_no ,       part_no  ,   location ,
           description ,  plan_qty ,   used_qty ,
           attrib ,       uom ,        conv_factor ,
           who_entered ,  note ,       lb_tracking ,
           bench_stock,   status ,     constrain ,
           plan_pcs ,     pieces,      scrap_pcs,
           part_type,     direction,   cost_pct,
           p_qty,         p_line,      p_pcs )
SELECT     prod_no ,      prod_ext ,   line_no ,
           seq_no ,       part_no  ,   location ,
           description ,  plan_qty ,   used_qty ,
           attrib ,       uom ,        conv_factor ,
           who_entered ,  note ,       lb_tracking ,
           bench_stock,   status ,     constrain ,
           plan_pcs ,     pieces,      scrap_pcs,
           part_type,     -1,          0,
           p_qty,         p_line,      p_pcs
FROM temp_prod_list
WHERE temp_prod_list.prod_no=@pno and temp_prod_list.prod_ext=@pext
ORDER BY seq_no,line_no
UPDATE prod_list 
set part_type='C',constrain='C' 
where prod_no=@pno and prod_ext=@pext and line_no=@exlno
DELETE temp_prod_list where prod_no=@pno and prod_ext=@pext
return 1
END
GO
GRANT EXECUTE ON  [dbo].[fs_expand_plist] TO [public]
GO
