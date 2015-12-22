SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[mls_pick_lot_bin] @loc varchar(10), @pno varchar(30),@from char(1), @tran int, @ext int, 
@uom char(2), @uqty decimal(20,8), @convfact decimal(20,8), @line int, @who varchar(20)
AS 
BEGIN
declare @iss int, @mline int, @direction int
declare @rqty decimal(20,8),@rcpt_sel int
declare @tuom decimal(20,8),@ck_row int,@sq decimal(20,8), @lp int, @lot varchar(25), @bin varchar(12),
@expdt datetime, @cost money, @qty decimal(20,8)
select @lp=1, @qty=(@uqty * @convfact), @rcpt_sel = 0

if @uqty = 0 return 0

if @from = '2'
begin
begin tran
update next_iss_no set last_no = last_no + 1
select @iss = last_no from next_iss_no
insert issues(
issue_no,part_no,location_from,location_to,avg_cost,who_entered,code,
issue_date,note,qty,inventory,direction,
lb_tracking,direct_dolrs,ovhd_dolrs,util_dolrs,labor,reason_code,qc_no,
status,journal_ctrl_num,reference_code,project1,project2,project3)
select @iss, @pno, @loc, NULL,
case when i.inv_cost_method = 'S' then i.std_cost else i.avg_cost end,
'epicor','PHY',getdate(),NULL,@uqty,'N',
1,'Y',
case when i.inv_cost_method = 'S' then i.std_direct_dolrs else i.avg_direct_dolrs end,
case when i.inv_cost_method = 'S' then i.std_ovhd_dolrs else i.avg_ovhd_dolrs end,
case when i.inv_cost_method = 'S' then i.std_util_dolrs else i.avg_util_dolrs end,
0,NULL,0,'S','','','','',''
from inventory i
where i.part_no = @pno and i.location = @loc

INSERT INTO lot_serial_bin_issue(
line_no, tran_no, tran_ext, part_no, location, bin_no, tran_code, 
date_tran, date_expires, qty, direction, uom, conv_factor, who, cost, lot_ser, uom_qty)
values( 1, @iss, 0, @pno, @loc, 'N/A','S',getdate(),getdate(),@uqty,1,'EA',1,
'epicor',0,'N/A',@uqty)

commit tran
end

if @from = '3'
begin
select @direction = 1
if @uqty < 0 
begin
select @direction = -1, @uqty = abs(@uqty)
end 

begin tran
update next_iss_no set last_no = last_no + 1
select @iss = last_no from next_iss_no
insert issues(
issue_no,part_no,location_from,location_to,avg_cost,who_entered,code,
issue_date,note,qty,inventory,direction,
lb_tracking,direct_dolrs,ovhd_dolrs,util_dolrs,labor,reason_code,qc_no,
status,journal_ctrl_num,reference_code,project1,project2,project3)
select @iss, @pno, @loc, NULL,
case when i.inv_cost_method = 'S' then i.std_cost else i.avg_cost end,
'epicor','PHY',getdate(),NULL,@uqty,'N',
@direction,'Y',
case when i.inv_cost_method = 'S' then i.std_direct_dolrs else i.avg_direct_dolrs end,
case when i.inv_cost_method = 'S' then i.std_ovhd_dolrs else i.avg_ovhd_dolrs end,
case when i.inv_cost_method = 'S' then i.std_util_dolrs else i.avg_util_dolrs end,
0,NULL,0,'S','','','','',''
from inventory i
where i.part_no = @pno and i.location = @loc

select @iss
commit tran

return
end

if @from = 'R' and @qty > 0
begin
  select @rqty = isnull((select sum(r.qty * r.direction)
  from lot_bin_recv r, lot_bin_stock s where r.tran_no = @tran and r.part_no = @pno
    and r.location = @loc 
    and s.part_no = r.part_no and s.location = r.location and s.bin_no = r.bin_no
    and s.lot_ser = r.lot_ser),0)

select @rqty
  if @rqty > 0
  begin
    delete from lbr 
    from lot_bin_recv lbr where tran_no = @tran and part_no = @pno and 
    location = @loc 
    and exists (select 1 from lot_bin_stock lbs where lbs.part_no = lbr.part_no
    and lbs.location = lbr.location and lbs.bin_no = lbr.bin_no and 
    lbs.lot_ser = lbr.lot_ser)

    select @qty = @qty - @rqty
    if @qty <= 0	return 0
  end
  select @rcpt_sel = 1
end

if @uqty > 0 
begin

if not exists (select 1 from lot_bin_stock 
where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%') return 0

while @lp > 0
BEGIN
set rowcount 1
if @rcpt_sel = 1
begin
  select @sq=s.qty, @lot=s.lot_ser, @bin=s.bin_no, @expdt=s.date_expires, @cost=s.cost
  from lot_bin_stock s, lot_bin_recv r
  where @pno=s.part_no and @loc=s.location and s.bin_no != 'IN TRANSIT' 
    and s.bin_no not like 'QC%' 
    and r.part_no = s.part_no and r.location = s.location and r.lot_ser = s.lot_ser
    and r.direction = 1
  order by r.lot_ser, s.date_expires

  if @@rowcount = 0
    select @rcpt_sel = 0
select @lot, @bin, @sq
end
if @rcpt_sel = 0
begin
  select @sq=qty, @lot=lot_ser, @bin=bin_no, @expdt=date_expires, @cost=cost
  from lot_bin_stock 
  where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%'
  order by date_expires
end
set rowcount 0
/* if sq is greater than qty than set to qty else we have them all from this bin */
if @sq >= @qty  select @lp=0, @sq=@qty
if @from = 'S'
begin
  if exists (select 1 from lot_bin_ship where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot)
  begin
    update lot_bin_ship 
    set qty = (qty * direction) - @sq, uom_qty = (uom_qty * direction) - (@sq/@convfact),
      direction = case sign((qty * direction) - @sq) when -1 then -1 else 1 end
    where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot
  end
  else
  begin
    insert into lot_bin_ship (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag)
    select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, @sq / @convfact , @convfact, @line, @who, 'N'
  end 
 	select @qty=@qty - @sq
end
if @from ='C'								-- mls 7/31/01 SCR 27322 start
begin
  if exists (select 1 from lot_bin_ship where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot)
  begin
    update lot_bin_ship 
    set qty = (qty * direction) - @sq, uom_qty = (uom_qty * direction) - (@sq/@convfact),
      direction = case sign((qty * direction) - @sq) when -1 then -1 else 1 end
    where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot
  end
  else
  begin
    insert into lot_bin_ship (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag,kit_flag)
  select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, @sq / @convfact , @convfact, @line, @who, 'N','Y'
  end
  select @qty=@qty - @sq
end
if @from='P' 
begin
  if exists (select 1 from lot_bin_prod where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot)
  begin
    update lot_bin_prod 
    set qty = (qty * direction) - @sq, uom_qty = (uom_qty * direction) - (@sq/@convfact),
      direction = case sign((qty * direction) - @sq) when -1 then -1 else 1 end
    where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot
  end
  else
  begin
    insert into lot_bin_prod (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag)
    select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, @sq / @convfact, @convfact, @line, @who, 'N'
  end
	select @qty=@qty - @sq
end
if @from='R' 
begin
  if exists (select 1 from lot_bin_recv where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot)
  begin
    update lot_bin_recv 
    set qty = (qty * direction) - @sq, uom_qty = (uom_qty * direction) - (@sq/@convfact),
      direction = case sign((qty * direction) - @sq) when -1 then -1 else 1 end
    where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot
  end
  else
  begin
    insert into lot_bin_recv (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag)
    select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, @sq / @convfact, @convfact, @line, @who, 'N'
  end
	select @qty=@qty - @sq
end
if @from='T' 
begin
  if exists (select 1 from lot_bin_xfer where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot)
  begin
    update lot_bin_xfer 
    set qty = (qty * direction) - @sq, uom_qty = (uom_qty * direction) - (@sq/@convfact),
      direction = case sign((qty * direction) - @sq) when -1 then -1 else 1 end
    where tran_no = @tran and tran_ext = @ext and
    line_no = @line and location = @loc and part_no = @pno and bin_no = @bin and 
    lot_ser = @lot
  end
  else
  begin
    insert into lot_bin_xfer (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	to_bin)
    select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, @sq / @convfact , @convfact, @line, @who, 'IN TRANSIT'
  end
	select @qty=@qty - @sq
end
if @from = 'I'
begin
  select @mline = isnull((select max(line_no) from lot_serial_bin_issue where tran_no = @tran),0) + 1
  insert into lot_serial_bin_issue(line_no,tran_no,tran_ext,part_no,location,bin_no,
    tran_code,date_tran,date_expires,qty,direction,uom,conv_factor,who,cost,lot_ser,uom_qty)
  select @mline,@tran, @ext, @pno, @loc, @bin, 'Q', getdate(),@expdt, @sq, -1, @uom, 
    @convfact, @who, @cost, @lot, @sq/@convfact

  select @qty=@qty - @sq
end
if @from in ('1','2')
begin
  set rowcount 1
  update lot_bin_stock
  set qty = qty - @sq
  where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%'
  and date_expires = @expdt
  set rowcount 0

  delete from lot_bin_stock
  where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%'
  and date_expires = @expdt and qty = 0
  select @qty = @qty - @sq
end
if not exists (select 1  from lot_bin_stock 
where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%') select @lp=0
END
end -- uqty > 0
if @uqty < 0
begin
if @from='P' 
begin
  select @lp = 1, @qty = abs(@qty)
  while @lp > 0
  BEGIN
  set rowcount 1
  select @sq=qty, @lot=lot_ser, @bin=bin_no, @expdt=date_expires
  from lot_bin_prod 
  where @pno=part_no and @loc=location and tran_no = @tran and tran_ext = @ext and line_no = @line
  order by date_expires
  set rowcount 0
  /* if sq is greater than qty than set to qty else we have them all from this bin */
  if @sq >= @qty  select @lp=0, @sq=@sq - @qty

  set rowcount 1
  update lot_bin_prod set qty = @sq, uom_qty = @sq / @convfact
  where @pno=part_no and @loc=location and tran_no = @tran and tran_ext = @ext and line_no = @line
    and lot_ser = @lot and bin_no = @bin and date_expires = @expdt
  set rowcount 0

  if @sq = 0
  begin
    delete lot_bin_prod
    where @pno=part_no and @loc=location and tran_no = @tran and tran_ext = @ext and line_no = @line
      and lot_ser = @lot and bin_no = @bin and date_expires = @expdt and qty = 0
  end
  end -- while
end
if @from='I' 
begin
  declare @lin int
  select @lp = 1, @qty = abs(@qty)
  while @lp > 0
  BEGIN
  set rowcount 1
  select @sq=qty, @lot=lot_ser, @bin=bin_no, @expdt=date_expires, @lin = line_no
  from lot_serial_bin_issue
  where @pno=part_no and @loc=location and tran_no = @tran and tran_ext = @ext 
  order by line_no desc,date_expires
  set rowcount 0
  /* if sq is greater than qty than set to qty else we have them all from this bin */
  if @sq >= @qty  
    select @lp=0, @sq=@sq - @qty
  else
    select @sq = 0, @qty = @qty - @sq

  set rowcount 1
  update lot_serial_bin_issue set qty = @sq, uom_qty = @sq / @convfact
  where @pno=part_no and @loc=location and tran_no = @tran and tran_ext = @ext and line_no = @lin
    and lot_ser = @lot and bin_no = @bin and date_expires = @expdt
  set rowcount 0

  if @sq = 0
  begin
    delete lot_serial_bin_issue
    where @pno=part_no and @loc=location and tran_no = @tran and tran_ext = @ext and line_no = @lin
      and lot_ser = @lot and bin_no = @bin and date_expires = @expdt and qty = 0
  end
  end -- while
end
end

END
GO
GRANT EXECUTE ON  [dbo].[mls_pick_lot_bin] TO [public]
GO
