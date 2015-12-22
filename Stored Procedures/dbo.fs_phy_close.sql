SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_phy_close] @phyid int ,
     @who varchar(30) ,
	 @apply_date datetime = NULL
As
  Begin






if @apply_date is null
  set @apply_date = getdate()

declare @x int, @y int,@tpart varchar(30), @loc varchar(10) 
declare @qty decimal(20,8), @pno int, @pt char(1)							-- mls 10/20/00 SCR 24582
declare @cost decimal(20,8), @direct decimal(20,8), @ovhd decimal(20,8)					-- mls 10/20/00 SCR 24582
declare @util decimal(20,8), @labor decimal(20,8), @edt datetime					-- mls 10/20/00 SCR 24582
declare @bin varchar(30), @lot varchar(30), @dir int  -- RLT 3/5/00 LOTSER
declare @note varchar(255), @lb_track char(1), @phyloc varchar(10)
declare @cnt int, @rtn int
 DECLARE @gl_method int, @tran_no int ,@tran_ext int ,@err int, @admmeth char(1)
 DECLARE @trx_type char(1)
 DECLARE @posting_code varchar(32),  @direct_acct varchar(32), @ovhd_acct varchar(32),@util_acct varchar(32),@inv_acct varchar(32)
declare @serial_flag int   -- RLT 3/5/00 LOTSER
DECLARE @account varchar(32) --RLT 24178 9/28/00
declare @loop_cnt int, @pos_qty decimal(20,8), @neg_qty decimal(20,8)
declare @inv_lot_bin char(1)

select @inv_lot_bin = left(isnull((select upper(value_str) from config (nolock) where flag = 'INV_LOT_BIN'),'Y'),1)

create table #tlotserial( tran_no int,tran_ext int, tran_code char(1),  location varchar(10), part_no varchar(30), bin_no varchar(12), lot_ser varchar(25),-- RLT 3/5/00 LOTSER
date_tran datetime, date_expires datetime NULL, qty decimal(20,8), direction int, who varchar(30), cost decimal(20,8), line_no int identity(1,1)) -- RLT 3/5/00 LOTSER

select @note = '* PHYSICAL INVENTORY *'

update physical set close_flag = 'Y' 
WHERE phy_batch = @phyid AND qty = orig_qty AND
 close_flag = 'N' and serial_flag <> 1  and isnull(lb_tracking,'N') = 'N'  -- RLT 3/5/00 LOTSER

-- This is to update the physical records for serial controlled items that need no issues made.


update physical set close_flag = 'Y' 
WHERE phy_batch = @phyid  AND close_flag = 'N' and
qty = orig_qty and (@inv_lot_bin != 'Y' or (@inv_lot_bin = 'Y' and -- mls 1/25/07 SCR 37415
((serial_flag = 1 or isnull(lb_tracking,'N') = 'Y')  -- RLT 3/5/00 LOTSER
and NOT exists (select * from lot_bin_phy lb where lb.phy_batch = @phyid
and lb.phy_no = physical.phy_no and lb.qty_physical <> lb.qty) )))

select @x=isnull( (select min(phy_no) 
 from physical
 where phy_batch = @phyid AND 
 close_flag = 'N'), 0 )
while @x > 0
begin

-- Get all the info for a issue transaction.  Qty and direction are a little tricky.  the qty is the absolute of the qty minus the original qty.  thus if you have 5 now and 10 originally
-- then you will have a five ( 5 - 10 = -5 absolute = 5) .  The rest is determined by the direction.  The direction is the absolute qty divided by the real qty and then you have either a 
-- one or negative one. ( as with the example above : absolute qty of 5 / real qty of -5 = -1.  A negative one means that you have an out transaction) so with them both you now know that
-- you have an out transaction for qty 5.
 select @tpart=part_no, @loc=location, @qty=abs(qty-orig_qty) , @dir = case when (qty-orig_qty) <> 0 then (abs(qty-orig_qty)/(qty-orig_qty)) else 1 end,
 @cost=avg_cost, @direct=avg_direct_dolrs, @ovhd=avg_ovhd_dolrs,  -- RLT 3/5/00 LOTSER
 @util=avg_util_dolrs, @labor=labor, @lb_track = lb_tracking , @serial_flag = serial_flag
 from physical
 where phy_batch = @phyid and phy_no = @x 

--Getting the account code that is set for Physical Counts. FYI if this was not entered into the 
-- issues table, the trigger for issues would get all this information and post everything correctly,
-- but it will not put the information into the table, so when you retrieve this record you would not 
-- see the account that the physical count entry was posted to.
select @account = account from issue_code where code = 'PHY' --RLT 24178 9/28/00

select @account = dbo.adm_mask_acct_fn(@account,dbo.adm_get_locations_org_fn(@loc))

-- mls 12/14/04 SCR 33596 - move to insert lot_serial_bin_issue before issues
truncate table #tlotserial

-- RLT 3/5/00 LOTSER start
--if you wonder why there is a case statement here and not above, the reason is because above there can be no final qty of zero because they are already taken care of
-- down here there can be a final qty of zero because you are determining it now.
-- Also the reason for the temp table is to create the line no, which is just an identity column to increment by 1.  
if @inv_lot_bin = 'Y'
begin
insert into #tlotserial
(tran_no,tran_ext, tran_code, part_no, location, bin_no, lot_ser, date_tran, date_expires,
qty, direction, cost,who)
select @pno, 0,'I', part_no, location, isnull(bin_no,''),isnull(lot_ser, ''), date_tran,date_expires, (abs(qty_physical - qty)), Case When (qty_physical - qty) <> 0 THEN (abs(qty_physical - qty)/(qty_physical - qty)) Else 1 END,  0.0, @who -- RLT 8/25/00
from lot_bin_phy
where phy_batch = @phyid and phy_no = @x

delete from #tlotserial where qty = 0
end

select @loop_cnt = 0, @pos_qty = 0, @neg_qty = 0

select @pos_qty = isnull((select sum(qty * direction) from #tlotserial where (qty * direction) > 0),0)
select @neg_qty = isnull((select sum(qty * direction) from #tlotserial where (qty * direction) < 0),0)

if @neg_qty < 0 select @loop_cnt = 1
if @pos_qty > 0 select @loop_cnt = 2

if @qty != 0 and @loop_cnt = 0  select @loop_cnt = 1

Begin TRAN

while (@loop_cnt > 0)
begin
  update next_iss_no set last_no=(last_no + 1)
  where last_no = last_no

  select @pno=last_no from next_iss_no

    --This insert inserts all the info you have collected that will change.  Any lot or serial or bin info that has changed will create a issue.  If zero qty(nothing changed) then don't change anything.
  if @loop_cnt = 2	-- positive lb qty
  begin
    insert into lot_serial_bin_issue
    (tran_no,tran_ext, tran_code, part_no, location,bin_no, lot_ser, date_tran, date_expires,qty,direction, who, line_no)
    select @pno, tran_ext, tran_code, part_no, location, bin_no, lot_ser, date_tran, date_expires, qty, 1,  who, line_no
    from #tlotserial
    where (qty * direction) > 0
    select @qty = @pos_qty, @dir = 1
  end

  if @loop_cnt = 1	-- negative lb qty or not lb tracked
  begin
    if @inv_lot_bin = 'Y'
    begin
      insert into lot_serial_bin_issue
      (tran_no,tran_ext, tran_code, part_no, location,bin_no, lot_ser, date_tran, date_expires,qty,direction, who, line_no)
      select @pno, tran_ext, tran_code, part_no, location, bin_no, lot_ser, date_tran, date_expires, abs(qty), -1,  who, line_no
      from #tlotserial
      where (qty * direction) < 0
      if @neg_qty < 0  select @qty = abs(@neg_qty), @dir = -1
    end
    if @inv_lot_bin = 'R' and @qty < 0 and @lb_track = 'Y'
    begin
      insert into lot_serial_bin_issue
      (tran_no,tran_ext, tran_code, part_no, location,bin_no, lot_ser, date_tran, date_expires,qty,direction, who, line_no)
      select @pno, 0, 'I', part_no, location, 'N/A', 'N/A', getdate(), getdate(), abs(@qty), -1,  @who, 1
      from physical
      where phy_batch = @phyid and phy_no = @x 
      if @qty  < 0  select @qty = abs(@qty), @dir = -1
    end
  end 

  if @@error <> 0 
  begin
    Rollback TRAN
    select -1
    return
  end
  --make an issue.
  insert into issues_all 
   ( issue_no, 
part_no, 
location_from, 
avg_cost, 
who_entered, 
code, 
reason_code, --RLT 24178 9/28/00
issue_date, 
note, 
qty, 
direction, 
lb_tracking, 
direct_dolrs, 
ovhd_dolrs, 
util_dolrs, 
labor,
mtrl_account_expense,--RLT 24178 9/28/00
direct_account_expense,--RLT 24178 9/28/00
ovhd_account_expense,--RLT 24178 9/28/00
util_account_expense--RLT 24178 9/28/00

 )
values( 
@pno, 
@tpart, 
@loc, 
isnull(@cost,0.0), 
@who, 
'PHY', 
'PHYSICAL',
@apply_date,	-- mls 5/6/08
@note, 
@qty,
@dir, 
@lb_track, 
isnull( @direct, 0.0),
isnull(@ovhd,0.0), 
isnull( @util,0.0), 
isnull(@labor,0.0),
@account,--RLT 24178 9/28/00
@account,--RLT 24178 9/28/00
@account,--RLT 24178 9/28/00
@account--RLT 24178 9/28/00


)


 if @@error <> 0 begin
	Rollback TRAN
	select -1
	return
 end

 update physical 
 set close_flag='Y' 
 where phy_batch = @phyid and phy_no = @x

 if @@error <> 0 begin
	Rollback TRAN
	select -2
	return
 end

  if @loop_cnt = 1  select @loop_cnt = 0
  if @loop_cnt = 2  select @loop_cnt = case when @neg_qty < 0 then 1 else 0 end
end

 Commit TRAN

 select @x=isnull( (select min(phy_no) 
 from physical
 where phy_batch = @phyid AND close_flag = 'N'), 0)

end

--Then you update the lot bin records accordingly.
update lot_bin_phy set close_flag = 'Y' where close_flag = 'N' and phy_batch = @phyid and phy_no in (select phy_no from
physical where close_flag = 'Y' and phy_batch = @phyid)

select @rtn=1
select @cnt=count(*) from physical where phy_batch=@phyid and close_flag='N'

if @cnt = 0 begin
 update phy_hdr set status='Y', date_closed=getdate(), who_closed=@who where phy_batch=@phyid
 if @@error <> 0 begin
	select -3
	return
 end
end
else begin
 select -4
 return
end

return @rtn

End

GO
GRANT EXECUTE ON  [dbo].[fs_phy_close] TO [public]
GO
