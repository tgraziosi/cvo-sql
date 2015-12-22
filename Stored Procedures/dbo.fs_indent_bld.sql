SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_indent_bld] @current varchar(30), @loc varchar(10), 
 @ctype char(1), @curqty money AS

declare @lev int, @x int, @eoq decimal(20,8) 
declare @qty decimal(20,8), @qtyext decimal(20,8)
declare @req_pn varchar(30), @seq varchar(10)
declare @srt varchar(255), @stat char(1)
declare @parent varchar(30), @assy char(1)
declare @curqty_dec decimal(20,8)
select @req_pn = @current
set nocount on

create table #tbom1
 ( part varchar(30), location varchar(10), 
 description varchar(255) NULL, qty decimal(20,8), 
 qty_ext decimal(20,8), cost decimal(20,8), 
 labor money, type char(10) NULL, 
 req_pn varchar(30) NULL, uom varchar(6) NULL, 
 seq_no varchar(10) NULL, ilevel int, 
 note varchar(255) NULL, sort_seq varchar(255),
 direct_dolrs decimal(20,8), ovhd_dolrs decimal(20,8),
 util_dolrs decimal(20,8), assy_flag char(1),
 parent varchar(30) NULL, status char(1) NULL,
 indent_part varchar(255), parent_eoq decimal(20,8),
 fixed char(1),		 row_id int identity(1,1) 
 )
select @lev=0
select @curqty_dec = @curqty
select @eoq = 0										 -- mls 6/14/99 SCR 70 19654

insert into #tbom1
select part_no, @loc, null, 
  qty, case when fixed = 'Y' then qty else (qty * @curqty_dec) end, 
  0, 0, null, @current, null, seq_no, @lev, note, '!'+seq_no, 0,
  0, 0, active , @current, active, part_no, @eoq, fixed
from what_part 
where asm_no=@current and active < 'M' and
  ( what_part.location = @loc OR what_part.location = 'ALL' )
order by seq_no

update #tbom1
set description = i.description,
  assy_flag = i.status,
  type = i.type_code,
  uom = i.uom
from inv_master i
where #tbom1.part = i.part_no

select @x = isnull((select min(row_id) from #tbom1 where assy_flag < 'N'),0)
while @x > 0
begin
  select @current = part, @qty = qty, @qtyext = qty_ext, 
    @seq = seq_no, @srt = sort_seq, @lev = ilevel,
    @stat = status, @assy = assy_flag, @parent = parent
  from #tbom1
  where row_id = @x

  if @assy < 'N' and @stat != 'F' 
  begin	
    insert into #tbom1
    select part_no, @loc, null, qty, case when fixed = 'Y' then qty else qty * @qtyext end, 
      0, 0, null, @req_pn,
      null, seq_no, @lev+1, note, @srt+seq_no, 0,  0, 0, active ,
      @current, 'F', Space((5 * (@lev+1)))+part_no, @eoq, fixed
    from what_part 
    where asm_no=@current and active < 'M' and
      ( what_part.location = @loc OR what_part.location = 'ALL' )
    order by seq_no
  end 

  if @stat = 'F' 
  begin 
    update #tbom1
    set description = 'FEATURE',
      type = '',
      uom = '',
      seq_no = ''
    where row_id = @x
 
    insert into #tbom1
    select option_part, @loc, null, default_qty, default_qty*@qtyext, 0,
      0, null, @req_pn, null, @seq, @lev+1, null, @srt+@seq, 0,  0, 0, 'N' ,
      @current, 'F', Space((5 * (@lev+1)))+option_part, @eoq, 'N'
    from options
    where part_no=@parent and feature = @current and default_flag = 'Y'
  end 

  update #tbom1
  set description = i.description,
    assy_flag = i.status,
    status = i.status,
    type = i.type_code,
    uom = i.uom
  from inv_master i
  where #tbom1.part = i.part_no and #tbom1.status = 'F' and 
    #tbom1.parent = @current and ilevel > @lev

  update #tbom1
  set assy_flag = 'X'
  where row_id = @x

  select @x = isnull((select min(row_id) from #tbom1 where row_id > @x and assy_flag < 'N'),0)	-- mls #4
end 

if @ctype = 'A'
begin
 UPDATE #tbom1
 SET #tbom1.cost = case when i.status = 'R' then 0 else i.avg_cost end,
   #tbom1.labor = case when i.status = 'R' then 0 else i.labor end,
   #tbom1.direct_dolrs = case when i.status = 'R' then i.std_direct_dolrs else i.avg_direct_dolrs end,
   #tbom1.ovhd_dolrs = case when i.status = 'R' then i.std_ovhd_dolrs else i.avg_ovhd_dolrs end,
   #tbom1.util_dolrs = case when i.status = 'R' then i.std_util_dolrs else i.avg_util_dolrs end
 FROM #tbom1, inventory i
 WHERE #tbom1.part=i.part_no and #tbom1.location=i.location
end

if @ctype = 'C'
begin
 UPDATE #tbom1
 SET #tbom1.cost = case i.status when 'M' then i.avg_cost else i.cost end,
   #tbom1.labor = i.labor,
   #tbom1.direct_dolrs = i.avg_direct_dolrs,
   #tbom1.ovhd_dolrs = i.avg_ovhd_dolrs,
   #tbom1.util_dolrs = i.avg_util_dolrs
 FROM #tbom1, inventory i
 WHERE #tbom1.part=i.part_no and #tbom1.location=i.location
end

if @ctype = 'S'
begin
 UPDATE #tbom1
 SET #tbom1.cost = i.std_cost,
   #tbom1.labor = i.std_labor,
   #tbom1.direct_dolrs = i.std_direct_dolrs,
   #tbom1.ovhd_dolrs = i.std_ovhd_dolrs,
   #tbom1.util_dolrs = i.std_util_dolrs
 FROM #tbom1, inventory i
 WHERE #tbom1.part=i.part_no and #tbom1.location=i.location
end

UPDATE #tbom1
SET #tbom1.cost = 0,
 #tbom1.direct_dolrs = 0,
 #tbom1.ovhd_dolrs = 0,
 #tbom1.util_dolrs = 0,
 #tbom1.assy_flag = 'Y'
WHERE exists ( select 1 from what_part w where #tbom1.part=w.asm_no ) and	     --	mls 7/6/00  scr 70 19709 
#tbom1.assy_flag = 'X'							   	     --	mls 7/6/00  scr 70 19709

UPDATE #tbom1
SET #tbom1.labor = 0
WHERE #tbom1.assy_flag='N'

select ilevel, seq_no, indent_part, description, qty, qty_ext, cost, 
 labor, type, uom, note, req_pn, sort_seq, direct_dolrs, 
 ovhd_dolrs, util_dolrs, @curqty, location, @ctype 
from #tbom1

order by sort_seq, part
GO
GRANT EXECUTE ON  [dbo].[fs_indent_bld] TO [public]
GO
