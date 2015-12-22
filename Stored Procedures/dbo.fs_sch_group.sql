SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[fs_sch_group] @batch_id varchar(20)
as 


declare    @demand_dt    datetime,
    @ord_min    decimal(20,8),
    @ord_mult    decimal(20,8),
    @need_qty    decimal(20,8),
    @group_qty    decimal(20,8),
    @next_qty    decimal(20,8),
    @control_qty  decimal(20,8),
    @unit_cost    decimal(20,8), 
    @period     int,
    @group_no    int,
    @next_row    int,
    @row_inserted  char(1),
    @part      varchar(30),
    @location    varchar(10),
    @vendor      varchar(12),
    @uom      varchar(10),
    @blanket_po    varchar(16),
    @home_curr    varchar(10),
    @po_curr    varchar(16),
    @rd_row     int,
  @last_part varchar(30),
  @last_loc varchar(10),
@tgroup varchar(20),
@buyer varchar(10)						-- mls 1/30/02 SCR 28265
CREATE TABLE #resource_demand_group (
  batch_id varchar (20) NOT NULL ,
  group_no varchar (20) NULL ,
  part_no varchar (30) NOT NULL ,
  qty decimal(20, 8) NOT NULL ,
  demand_date datetime NOT NULL ,
  location varchar (10) NOT NULL ,
  vendor_no varchar (12) NULL ,
  buy_flag char (1) NOT NULL  DEFAULT ('N'),
  uom varchar (10) NOT NULL ,
  unit_cost decimal(20, 8) NOT NULL  DEFAULT (0),
  distinct_order_flag char (1) NOT NULL  DEFAULT ('N'),
  blanket_order_flag char (1) NOT NULL  DEFAULT ('N'),
  blanket_po_no varchar (16) NULL ,
  xfer_order_flag char (1) NOT NULL  DEFAULT ('N'),
  location_from varchar (10) NULL ,
  curr_key varchar (10) NOT NULL
)



--******************************************************************************
--* Obtain the user's selection criteria for the length of the period to combine
--* demands together and suggest one purchase release.  Initialize the group 
--* number counter and create a temp table to use in grouping demand rows together.
--* Obtain the company's home currency code.
--******************************************************************************
SELECT  @period    = combine_days
FROM  resource_batch (nolock)
WHERE  batch_id   = @batch_id

select @group_no = 0

CREATE TABLE  #temp_group(
  tdrow    int,
  tqty    decimal(20,8),
  tdemand_dt  datetime,
  tincl_flag  char(1),
  trow_id    int identity)

create index #tempg1 on #temp_group(tincl_flag, trow_id)

select @home_curr = IsNull((SELECT home_currency FROM glco (nolock)),'')
select @last_part = '', @last_loc = ''

--******************************************************************************
--* Find the first part number with demand
--******************************************************************************
DECLARE c_res_demand CURSOR LOCAL FOR
SELECT DISTINCT t.part_no, t.location, m.vendor, m.uom, l.min_order, l.order_multiple,
  isnull(a.nat_cur_code,@home_curr), t.buyer				-- mls 1/30/02 SCR 28265
from #resource_demand t (nolock)
JOIN inv_master m (nolock) on m.part_no = t.part_no
JOIN inv_list l (nolock) on l.part_no = t.part_no and l.location = t.location
left outer join adm_vend_all a (nolock) on a.vendor_code = m.vendor
where t.status = 'X' and t.group_no is NULL and t.qty > 0
group by t.part_no, t.location, m.vendor, m.uom, l.min_order, l.order_multiple,
a.nat_cur_code, t.buyer							-- mls 1/30/02 SCR 28265
order by t.part_no, t.location

OPEN c_res_demand

FETCH NEXT FROM c_res_demand into @part, @location, @vendor, @uom, @ord_min, @ord_mult, @po_curr,
  @buyer								-- mls 1/30/02 SCR 28265
while @@FETCH_STATUS = 0
begin

    select @control_qty = 0,      -- control for calling fs_sch_purchase_info
      @blanket_po = NULL,
      @unit_cost = 0        -- skk 03/22/01 SCR 26350


  --**********************************************************************
  --* Find the start of the first time period with demand for this
  --* part number in this location
  --**********************************************************************
  SELECT  @demand_dt  = IsNull((  SELECT  MIN(demand_date)
  FROM  #resource_demand
  WHERE  status    = 'X' and group_no  is NULL and qty    > 0 and
    part_no    = @part and location  = @location), '1900-01-01 00:00:00:000')


  --**********************************************************************
  --* If the first demand date is prior to today, then adjust the period
  --* start date so that all "past due" demands get lumped into the first
  --* grouping period starting with today.
  --**********************************************************************  
  if (@demand_dt <> '1900-01-01 00:00:00:000') 
    and (@demand_dt < convert(char(8), getdate(), 1) + ' 00:00:00:000')
  begin
    select @demand_dt = convert(char(8), getdate(), 1) + ' 00:00:00:000'
  end
    
  while @demand_dt > '1900-01-01 00:00:00:000'
  begin
    --******************************************************************
    --* We are creating a new summary group so increment the group number.
    --* Clear the temp table and then insert it with all un-grouped rows
    --* from resource_demand for this part_no/location.  As the rows are
    --* being inserted, the include_flag will be set to 'Y' if the 
    --* demand_date falls within the combine period we are currently
    --* working with.  The rows will be inserted in demand_date order so
    --* that we can move additional future demand into this combine period
    --* grouping.  This is needed if we have to order extra quantity over
    --* the actual demand to fulfill order minimums/multiples. 
    --******************************************************************
    select @group_no = @group_no + 1

    Truncate table #temp_group

    INSERT  #temp_group(tdrow, tqty, tdemand_dt, tincl_flag)
    SELECT  row_id, qty, demand_date,
      (case when demand_date < DATEADD(day, @period, @demand_dt) then 'Y' else 'N' end)
    FROM  #resource_demand
    WHERE  part_no    = @part and location  = @location and group_no  is NULL and qty    > 0
    ORDER BY demand_date, qty

    UPDATE  #resource_demand
    SET  group_no  = convert(varchar(20), @group_no)
    FROM  #temp_group
    WHERE  #resource_demand.row_id  = #temp_group.tdrow and #temp_group.tincl_flag  = 'Y'
      
    --******************************************************************
    --* Calculate the actual qty needed for the demand rows that fall 
    --* within this combine period grouping, and then determine if we 
    --* need to increase the order to fulfill order minimums/multiples.
    --* Insert resource_demand_group with the suggested PO release.
    --******************************************************************
    SELECT  @need_qty = (  SELECT  SUM(tqty) FROM   #temp_group WHERE  tincl_flag = 'Y')
      
    select @group_qty = @need_qty
      
    if @ord_mult > 0
      select @group_qty = @ord_mult * (1 + floor((@need_qty - 1)/@ord_mult))

    if @group_qty < @ord_min
      select @group_qty = @ord_min

    --******************************************************************
    --* Now that we know how many we need to order, call fs_sch_purchase_info
    --* to look for an open blanket PO or a valid vendor quote.  We call
    --* this proc the first time through for this part/location and then
    --* only if the quantity changes when there is no blanket PO.
    --******************************************************************
    if (@control_qty <> @group_qty and @blanket_po is NULL)
    begin
      EXEC fs_sch_purchase_info @part, @location, @vendor OUTPUT, @group_qty,
        @po_curr OUTPUT, @unit_cost OUTPUT, @blanket_po OUTPUT
      select @control_qty = @group_qty
    end

    INSERT  #resource_demand_group(
      batch_id, group_no, part_no, qty, demand_date, location, vendor_no,
      uom, unit_cost, curr_key, blanket_order_flag, blanket_po_no)
    VALUES  (@batch_id, convert(varchar(20), @group_no), @part, @group_qty,
      @demand_dt, @location, @vendor, @uom, @unit_cost, @po_curr,
      (case when @blanket_po is NOT NULL then 'Y' else 'N' end),
      @blanket_po)

    --******************************************************************
    --* If we had to increase the order qty in order to meet an order
    --* minimum or a multiple, then we have additional supply available
    --* within this grouping.  Let's see if we can move future demand
    --* into this group to consume this supply before we suggest any 
    --* more orders for this part/location.  Whether we move rows or not,
    --* we need to insert a (R)ounding row in resource_demand indicating
    --* that we adjusted the order qty.
    --******************************************************************
    while @group_qty > @need_qty
    begin
      select @row_inserted = 'N'    -- loop control flag
        
      --**************************************************************
      --* Look for another demand row for this part/location.
      --**************************************************************
      select @next_row =   IsNull((SELECT  MIN(trow_id)
        FROM  #temp_group WHERE  tincl_flag = 'N'), 0)

      while (@next_row > 0 and @row_inserted = 'N')
      begin
        --**********************************************************
        --* If there is another demand row for this part/location,
        --* then determine if the qty needed will "fit" into the
        --* group we are working with.  We only do this if we haven't
        --* already inserted a (R)ounding demand row in resource_demand.
        --* That could have happened if, in a previous time through
        --* this loop, we found additional demand but it was greater
        --* than the supply remaining in this grouping.
        --**********************************************************
        SELECT  @next_qty =  tqty,
          @rd_row = tdrow 
        FROM  #temp_group
        WHERE  tincl_flag = 'N' and trow_id = @next_row

        if (@need_qty + @next_qty) <= @group_qty
        begin
          --******************************************************
          --* OK, there is an additional demand row and it will "fit"
          --* into the excess supply we have available in this group.
          --* Update the tables to include this demand in the group
           --* and then look for another row.
          --******************************************************
          select @need_qty = @need_qty + @next_qty

          UPDATE  #temp_group
          SET  tincl_flag  = 'Y'
          WHERE  tincl_flag = 'N' and trow_id    = @next_row
      
          UPDATE  #resource_demand
          SET  group_no  = @group_no
          WHERE  #resource_demand.row_id  = @rd_row

          select @next_row =   IsNull((SELECT  MIN(trow_id)
            FROM  #temp_group WHERE  tincl_flag = 'N' ), 0)
        end
        else
        begin
          --******************************************************
          --* There is an additional demand row but the qty needed
          --* is more than the excess supply we have available in
          --* this group. We need to split up this demand so that a
          --* a portion of it consumes the remaining supply in this
          --* group, and then the remainder goes into the next group.
          --* We do this by creating a new (R)ounding demand row in
          --* this group and reducing the qty in the existing row.
          --******************************************************
          UPDATE  #resource_demand
          SET  qty    = (qty - (@group_qty - @need_qty))
          WHERE  #resource_demand.row_id  = @rd_row

          INSERT  #resource_demand( batch_id, group_no, part_no,
            qty, demand_date, ilevel, location, source, status,
            commit_ed, source_no, parent, pqty, p_used, type, uom,      -- skk 03/01/01 SCR 26096
            buyer)							-- mls 1/30/02 SCR 28265
          SELECT  @batch_id, @group_no, @part, (@group_qty - @need_qty),
            demand_date, ilevel, location, 'R', status, commit_ed,
            source_no, parent, pqty, p_used, type, @uom,      -- skk 03/01/01 SCR 26096
            @buyer							-- mls 1/30/02 SCR 28265
          FROM  #resource_demand
          WHERE  #resource_demand.row_id  = @rd_row

          --******************************************************
          --* We've used up all of the supply in this group so we're
          --* done with it.  Set the @row_inserted flag so that we
          --* fall out of the inner loop.  Set the qty's equal to 
          --* exit the outer loop and start building the next group
          --* summary for this part/location.
          --******************************************************
          select @need_qty = @group_qty,
            @row_inserted = 'Y'
        end -- if (@need_qty + @next_qty) <= @group_qty
      end -- while (@next_row > 0 and @row_inserted = 'N')

      if @row_inserted = 'N'
      --**************************************************************
      --* If we get here, that means we have excess supply in the current
      --* group, but we didn't find any more future demand rows to move
      --* up.  Insert a (R)ounding demand row to consume the remaining
      --* supply.
      --**************************************************************
      begin
        INSERT  #resource_demand( batch_id, group_no, part_no,
          qty, demand_date, ilevel, location, source, status,
          commit_ed, source_no, parent, pqty, p_used, type, uom,      -- skk 03/01/01 SCR 26096
          buyer)							-- mls 1/30/02 SCR 28265
        VALUES  (@batch_id, @group_no, @part, (@group_qty - @need_qty),
          @demand_dt,    -- skk 03/01/01 SCR 26906
          0, @location, 'R', 'X', 0, '0',      -- skk 03/01/01 SCR 26096
          '', 1, 0, 'P', @uom,      -- skk 03/01/01 SCR 26096
	  @buyer )							-- mls 1/30/02 SCR 28265

        select @need_qty = @group_qty 
            
      end -- if @row_inserted = 'N'
    end -- while @group_qty > @need_qty

    --******************************************************************
    --* Get the next demand date grouping for this part number and location
    --******************************************************************
    SELECT  @demand_dt  = IsNull((  SELECT  MIN(demand_date)
      FROM  #resource_demand
      WHERE  status    = 'X' and group_no  is NULL and qty    > 0 and
        part_no    = @part and location  = @location), '1900-01-01 00:00:00:000')
  end -- while @demand_dt > '1900-01-01 00:00:00:000'

  FETCH NEXT FROM c_res_demand into @part, @location, @vendor, @uom, @ord_min, @ord_mult, @po_curr,
    @buyer								-- mls 1/30/02 SCR 28265
end 

CLOSE c_res_demand
DEALLOCATE c_res_demand

DROP TABLE #temp_group

INSERT resource_demand_group(
  batch_id, group_no, part_no, qty, demand_date, location, vendor_no,
  uom, unit_cost, curr_key, blanket_order_flag, blanket_po_no)
select
  batch_id, group_no, part_no, qty, demand_date, location, vendor_no,
  uom, unit_cost, curr_key, blanket_order_flag, blanket_po_no
from #resource_demand_group

drop table #resource_demand_group
GO
GRANT EXECUTE ON  [dbo].[fs_sch_group] TO [public]
GO
