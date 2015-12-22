SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_phy_init] 
      @phy_id int, 
      @sort int,
      @loc1 varchar(10),
      @loc2 varchar(10),
      @part1 varchar(30),
      @part2 varchar(30),
      @bin1 varchar(12),
      @bin2 varchar(12),
      @group1 varchar(10),
      @group2 varchar(10),
      @restype1 varchar(10),
      @restype2 varchar(10),
      @cycle1 varchar(10),
      @cycle2 varchar(10),
      @description varchar(40),
      @who varchar(30) AS 
BEGIN
set nocount on


declare @allow_negs varchar(4), 
  @cnt int, 
  @InvLotBin varchar(20), 
  @BlindCount varchar(20),
  @IncludeAll varchar(20),        				-- mls 4/21/00 SCR 22715
  @IncludeHold varchar(20),  							-- mls 4/21/00 SCR 22715
  @ls_cnt int,
  @filter_on_bin int								-- mls 12/8/03 SCR 30475
declare @sql varchar(8000)
if @who is null select @who = 'UNKNOWN'

Begin TRAN

if @phy_id = 0 
begin
  Update next_phy_no Set last_no=last_no + 1
  select @phy_id=last_no from next_phy_no
  insert phy_hdr (phy_batch, status, sort_type, date_init, date_closed, who_init, who_closed, description)
  select @phy_id, 'N', @sort, getdate(), null, @who, null, @description 
end

select @allow_negs = isnull( (select upper(value_str) from config (nolock) where flag='INV_PHY_NEGS'), 'NO' )
if @allow_negs <> 'NO' select @allow_negs = 'YES'
select @BlindCount = isnull( (select upper(value_str) from config (nolock) where flag='INV_PHY_BLIND'), 'NO' )
if @BlindCount <> 'YES' select @BlindCount = 'NO'
select @InvLotBin = isnull( (select upper(value_str) from config (nolock) where flag='INV_LOT_BIN'), 'NO' )
if @InvLotBin like 'Y%' select @InvLotBin = 'YES'
select @IncludeAll = isnull( (select upper(value_str) from config (nolock) where flag='INV_PHY_ALL_PARTS'), 'NO' ) 
if @IncludeAll <> 'YES' select @IncludeAll = 'NO'      			  
select @IncludeHold = isnull( (select upper(value_str) from config (nolock) where flag='INV_PHY_W/HOLDS'), 'NO' ) 
if @IncludeHold <> 'YES' select @IncludeHold = 'NO'						   

DELETE FROM dbo.physical WHERE dbo.physical.phy_batch = @phy_id

create table #tpart (part_no varchar(30))
create index #tpart0 on #tpart(part_no)

create table #ttemp(   part_no varchar(30),   location varchar(10), 
  lb_tracking char(1),   category varchar(10),  type_code varchar(10), bin_no varchar(12),					-- mls 12/8/03 SCR 30475
  avg_cost decimal(20,8),
  cycle_type varchar(10),    qty decimal(20,8), serial_flag int              )

create table #tphysical(part_no varchar(30),   location varchar(10),   
  lb_tracking char(1),   category varchar(10),  type_code varchar(10), bin_no varchar(12),					-- mls 12/8/03 SCR 30475
  avg_cost decimal(20,8),
  cycle_type varchar(10),    qty decimal(20,8), serial_flag int,  row_id int identity(1,1)       )

create table #tfinal (part_no varchar(30),   location varchar(10),   
  lb_tracking char(1),   category varchar(10),  type_code varchar(10), bin_no varchar(12),					-- mls 12/8/03 SCR 30475
  cycle_type varchar(10),    qty decimal(20,8), serial_flag int,  row_id int identity(1,1)       )

create table #tlotserial(phy_batch int,  phy_no int, location varchar(10), part_no varchar(30), bin_no varchar(12),  lot_ser varchar(25), 
  date_tran datetime, date_expires datetime null, qty decimal(20,8), qty_physical decimal(20,8), cost decimal(20,8),
  row_id int identity (1,1)) 													-- mls 12/8/03 SCR 30475

create table #tlotfinal(phy_batch int,  phy_no int, location varchar(10), part_no varchar(30), bin_no varchar(12),  lot_ser varchar(25), 
  date_tran datetime, date_expires datetime null, qty decimal(20,8), qty_physical decimal(20,8), cost decimal(20,8),
  row_id int identity (1,1)) 													-- mls 12/8/03 SCR 30475


create index #tp0 on #tphysical(row_id)
create index #tp1 on #tphysical(location,part_no)
create index #tp2 on #tphysical(location,category,part_no)
create index #tp3 on #tphysical(location,type_code,part_no)
create index #tp4 on #tphysical(location,bin_no,part_no)

create index #tls0 on #tlotserial(phy_no)
create index #tls1 on #tlotserial(location,part_no)
create index #tls2 on #tlotserial(row_id)

select @sql = 'insert #tpart select  part_no from inv_master i (nolock)
  where i.status < ''Q'' and isnull(i.void,''N'') = ''N'' and i.status<>''C'''		-- mls 12/26/06 SCR 37217

if @loc1 = '' 
  select @loc1 = min(location) from locations (nolock) where void = 'N'

if @loc2 = '' 
  select @loc2 = max(location) from locations (nolock) where void = 'N'

if @part1 != '' and @part2 != ''
  select @sql = @sql + ' and (i.part_no between ''' + @part1 + ''' and  ''' + @part2 + ''')'
else
begin
  if @part1 != '' 
    select @sql = @sql + ' and (i.part_no >= ''' + @part1 + ''')'

  if @part2 != '' 
    select @sql = @sql + ' and (i.part_no <= ''' + @part2 + ''')'
end

-- Want to get rid of bins in this process
select @bin1 = isnull(@bin1,''), @bin2 = isnull(@bin2,'')

select @filter_on_bin = case when @bin1 = '' and @bin2 = '' then 0 else 1 end
select @bin2 = case when @bin2 = '' then 'ZZZZZZZZZZZZZZ' else @bin2 end

if @group1 != '' and @group2 != ''
  select @sql = @sql + ' and (i.category between ''' + @group1 + ''' and ''' + @group2 + ''')'
else
begin
  if @group1 != '' 
    select @sql = @sql + ' and (i.category >= ''' + @group1 + ''')'

  if @group2 != '' 
    select @sql = @sql + ' and (i.category <= ''' + @group2 + ''')'
end

if @restype1 != '' and @restype2 != ''
  select @sql = @sql + ' and (i.type_code between ''' + @restype1 + ''' and ''' + @restype2 + ''')'
else
begin
  if @restype1 != ''
    select @sql = @sql + ' and (i.type_code >= ''' + @restype1  + ''')'

  if @restype2 != ''
    select @sql = @sql + ' and (i.type_code <= ''' + @restype2 + ''')'
end

if @cycle1 != '' and @cycle2 != ''
  select @sql = @sql + ' and (i.cycle_type between ''' + @cycle1 + ''' and ''' +  @cycle2 + ''')' 
else
begin
  if @cycle1 != '' 
    select @sql = @sql + ' and (i.cycle_type >= ''' + @cycle1  + ''')' 

  if @cycle2 != '' 
    select @sql = @sql + ' and (i.cycle_type <= ''' + @cycle2 + ''')' 
end

exec(@sql)

insert   #ttemp ( part_no, location, lb_tracking, category, type_code, cycle_type, qty, serial_flag , bin_no, avg_cost)
select  part_no,   location, lb_tracking,   category,   type_code, cycle_type,  
  case when @IncludeHold = 'YES' and lb_tracking != 'Y'			-- mls 2/8/02 SCR 28327
    then in_stock + hold_ord + hold_mfg + hold_xfr + hold_rcv + hold_qty 	-- mls 4/21/00 SCR 22715
    else in_stock end,										    -- mls 4/21/00 SCR 22715 
  serial_flag, 
  isnull(bin_no,''),											-- mls 12/8/03 SCR 30475
  i.avg_cost
from inventory i
where   (i.location >= @loc1 and i.location <= @loc2) and i.part_no in (select part_no from #tpart)

delete #ttemp
from physical p
where   p.part_no = #ttemp.part_no and p.location = #ttemp.location and p.close_flag = 'N'

if @sort in (1,3,4)
begin
  if @sort = 1 
  begin
    insert   #tphysical (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag, avg_cost) 
    select  part_no,   location,lb_tracking,   category,   type_code, bin_no, cycle_type,    qty,
     serial_flag, avg_cost
    from  #ttemp
    where qty <> 0 or (qty = 0 and @IncludeAll = 'YES')				
    order by location,part_no
  end

  if @sort = 3 
  begin
    insert   #tphysical  (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag, avg_cost) 
    select  part_no,   location, lb_tracking,   category,   type_code, bin_no, cycle_type,    qty, serial_flag, avg_cost
    from  #ttemp
    where qty <> 0 or (qty = 0 and @IncludeAll = 'YES')  			
    order by location,category,part_no
  end

  if @sort = 4 
  begin
    insert   #tphysical (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag, avg_cost) 
    select  part_no,   location, lb_tracking,   category,   type_code, bin_no, cycle_type,    qty, serial_flag, avg_cost
    from  #ttemp
    where qty <> 0 or (qty = 0 and @IncludeAll = 'YES')  			
    order by location,type_code,part_no
  end

  if @InvLotBin = 'YES'
  begin
    if @filter_on_bin = 1											-- mls 12/8/03 SCR 30475
      delete from #tphysical 
      where not (lb_tracking = 'Y' or serial_flag = 1 ) and bin_no not between @bin1 and @bin2

    insert   #tlotserial (phy_batch, phy_no, location, part_no, bin_no, lot_ser, date_tran, date_expires, qty, qty_physical, cost)
    select  @phy_id, tp.row_id , tp.location, tp.part_no, isnull(l.bin_no,''), 
      isnull(l.lot_ser,'') ,getdate(),l.date_expires,   isnull(l.qty,0),0, tp.avg_cost    
    from  lot_bin_stock l, #tphysical tp
    where   (tp.part_no = l.part_no and tp.location = l.location) and
      (l.bin_no >= @bin1 and l.bin_no <= @bin2) and  -- mls 1/8/01 SCR 25559
      (tp.lb_tracking = 'Y' or tp.serial_flag = 1 ) 

    delete from p
    from #tphysical p
    where (p.lb_tracking = 'Y' or p.serial_flag = 1 ) and
      not exists (select 1 from #tlotserial l where l.part_no = p.part_no and l.location = p.location)
  end 
  else
  begin
    if @filter_on_bin = 1											-- mls 12/8/03 SCR 30475
      delete from #tphysical where bin_no not between @bin1 and @bin2
  end

  insert #tfinal (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag) 
  select part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag
  from #tphysical
  order by row_id

  insert #tlotfinal (phy_batch, phy_no, location, part_no, bin_no, lot_ser, date_tran, date_expires, qty, qty_physical, cost)
  select l.phy_batch, p.row_id, p.location, p.part_no, l.bin_no, l.lot_ser, l.date_tran, l.date_expires, l.qty, l.qty_physical, l.cost
  from #tlotserial l, #tfinal p
  where l.part_no = p.part_no and l.location = p.location 
  order by p.row_id, l.row_id
end

if @sort = 2 -- location/bin/item										-- mls 12/8/03 SCR 30475
begin
  insert   #tphysical (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag, avg_cost) 
  select  part_no,   location, lb_tracking,   category,   type_code, bin_no, cycle_type,  qty, serial_flag, avg_cost
  from  #ttemp
  where (qty <> 0 or (qty = 0 and @IncludeAll = 'YES'))  			
  order by location,bin_no,part_no

  if @InvLotBin = 'YES' 
  begin
    insert   #tlotserial (phy_batch, phy_no, location, part_no, bin_no, lot_ser, date_tran, date_expires, qty, qty_physical, cost)
    select  @phy_id, tp.row_id , tp.location, tp.part_no, isnull(l.bin_no,''), 
      isnull(l.lot_ser,'') ,getdate(),l.date_expires,   isnull(l.qty,0),0, tp.avg_cost    
    from  #tphysical tp
    join lot_bin_stock l on l.part_no = tp.part_no and l.location = tp.location 
    where (l.bin_no >= @bin1 and l.bin_no <= @bin2) and  						-- mls 1/8/01 SCR 25559
      (tp.lb_tracking = 'Y' or tp.serial_flag = 1 ) 
    order by tp.location, l.bin_no, tp.part_no

    insert   #tlotserial (phy_batch, phy_no, location, part_no, bin_no, lot_ser, date_tran, date_expires, qty, qty_physical, cost)
    select  @phy_id, tp.row_id , tp.location, tp.part_no, isnull(tp.bin_no,''), '' ,getdate(),NULL,   isnull(tp.qty,0),0, 0
    from #tphysical tp 
    where (tp.bin_no >= @bin1 and tp.bin_no <= @bin2) and  						-- mls 1/8/01 SCR 25559
      (tp.lb_tracking = 'N' and tp.serial_flag = 0 ) 
    order by tp.location, tp.bin_no, tp.part_no

    delete from p
    from #tphysical p
    where not exists (select 1 from #tlotserial l where l.part_no = p.part_no and l.location = p.location)

    insert #tfinal (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag) 	-- mls 8/31/04 SCR 33454
    select p.part_no, p.location, p.lb_tracking, p.category, p.type_code, l.bin_no, p.cycle_type, sum(l.qty), p.serial_flag
    from #tphysical p
    join #tlotserial l on l.phy_no = p.row_id
    group by p.part_no, p.location, p.lb_tracking, p.category, p.type_code, l.bin_no, p.cycle_type, p.serial_flag
    order by p.location, l.bin_no, p.part_no

    insert #tlotfinal (phy_batch, phy_no, location, part_no, bin_no, lot_ser, date_tran, date_expires, qty, qty_physical, cost)
    select l.phy_batch, p.row_id, p.location, p.part_no, p.bin_no, l.lot_ser, l.date_tran, l.date_expires, l.qty, l.qty_physical, l.cost
    from #tlotserial l, #tfinal p
    where l.part_no = p.part_no and l.location = p.location and l.bin_no = p.bin_no and l.lot_ser != ''
    order by p.row_id, l.row_id
  end 
  else
  begin
    if @filter_on_bin = 1						
      delete from #tphysical where bin_no not between @bin1 and @bin2

    insert #tfinal (part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag) 	-- mls 8/31/04 SCR 33454
    select part_no, location, lb_tracking, category, type_code, bin_no, cycle_type, qty, serial_flag
    from #tphysical
    order by location, bin_no, part_no
  end

end

select @cnt = count(*) from #tfinal
select @ls_cnt = count(*) from #tlotfinal


INSERT INTO dbo.physical (
  phy_batch,  phy_no,   location, part_no, qty,     date_entered,   who_entered, avg_cost,   avg_direct_dolrs, 
  avg_ovhd_dolrs, avg_util_dolrs, labor, close_flag,   orig_qty , lb_tracking, serial_flag    		)                      
SELECT   @phy_id,   row_id,    location,  part_no, 0,    getdate(),   @who, 0,0,0,0,0, 'N',    qty, lb_tracking, serial_flag
FROM #tfinal

INSERT INTO dbo.lot_bin_phy
  (phy_batch, phy_no, location, part_no, bin_no, date_tran, date_expires, qty, qty_physical, close_flag, lot_ser)
select @phy_id, phy_no, location, part_no, bin_no, date_tran,date_expires, qty, qty_physical, 'N', lot_ser
  from #tlotfinal

drop table #ttemp
drop table #tphysical
drop table #tlotserial  
drop table #tfinal
drop table #tlotfinal

if @ls_cnt > 0 or @cnt > 0 
begin
  Commit TRAN
end
else 
begin
  Rollback TRAN
  select @phy_id = 0
end

select @phy_id 'phy_batch', @cnt 'num_records',@ls_cnt 'num_serial_records'  

END

GO
GRANT EXECUTE ON  [dbo].[fs_phy_init] TO [public]
GO
