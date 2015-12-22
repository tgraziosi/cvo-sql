SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_step1] @batch_id varchar(20)    AS



declare	@demand_row		int,
	@avail_row		int,
	@level			int
declare	@demand_src		char(1),
	@avail_src		char(1),
	@ptype			char(1)
declare	@loc			varchar(10),
	@part			varchar(30),
	@demand_srcno	varchar(20),
	@avail_srcno	varchar(20),
	@parent			varchar(30)
declare	@demand_qty		decimal(20,8),
	@avail_qty		decimal(20,8)
declare	@demand_dt		datetime,
	@avail_dt		datetime


--******************************************************************************
--* Table resource_demand contains a column called status which indicates the 
--* the status of each demand row in the netting process.  Status values are:
--* 'N'ew	= not yet processed
--* 'P'arent	= unfilled demand for a parent item which has been exploded into
--*			demand for component items 
--* 'F'illed	= the demand has been completely filled
--* 'U'nfilled	= unfilled demand for a parent item which has yet to be exploded
--* 'X'		= Completed, no further processing. Orders will be suggested for
--*					non-zero quantities
--******************************************************************************

--******************************************************************************
--* Find the first unprocessed demand record - status = 'N'
--******************************************************************************
DECLARE c_res_demand CURSOR STATIC LOCAL FOR
SELECT	location, part_no, qty, demand_date, source, source_no, ilevel,
  parent, type, row_id
from #resource_demand
where status = 'N' and ilevel = 0
order by case when source = 'M' then 1 else 0 end,demand_date, row_id					-- mls 5/30/02 SCR 29003

OPEN c_res_demand

FETCH c_res_demand INTO @loc, @part, @demand_qty, @demand_dt, @demand_src,
  @demand_srcno, @level, @parent, @ptype, @demand_row

while @@FETCH_STATUS = 0
begin
  select @avail_qty = 0, @avail_row = 0
  --**************************************************************************
  --* Look in resource_avail for supply for this part number in this location.
  --* Get the first supply record which has not been applied to any demand and
  --* has the earliest available date.
  --**************************************************************************
  DECLARE c_res_avail CURSOR STATIC LOCAL FOR
  select row_id, qty, avail_date, source, source_no
  from #resource_avail
  where status = 'N' and part_no = @part and location = @loc and qty > 0
  ORDER BY avail_date, source, source_no
  
  OPEN c_res_avail

  FETCH c_res_avail INTO @avail_row, @avail_qty, @avail_dt, @avail_src, @avail_srcno

  while @@FETCH_STATUS = 0 and @demand_qty > 0
  begin
    if (@avail_qty > 0) and (@demand_qty > @avail_qty)
    --******************************************************************************
    --* We found some supply, but it is not enough to satisfy the demand coming from
    --* this demand record.  Set the supply record status to (X)Completed so we don't
    --* look at it again.  Insert table resource_depends to peg this supply to this
    --* demand.  The insert trigger on resource_depends will decrease the qty on the
    --* supply record to 0 and the qty on the demand record to the remainder qty 
    --* which still needs to be filled.  We leave the status of the demand record in
    --* resource_demand unchanged so that it will come up again next time through 
    --* the loop.
    --******************************************************************************
    begin
      UPDATE  #resource_avail
      SET  status  = 'X',
        qty = 0,
        commit_ed = commit_ed + @avail_qty
      WHERE  row_id  = @avail_row

      INSERT  resource_depends(
        batch_id, part_no, location, qty, avail_date, avail_source, avail_source_no,
        demand_source, demand_source_no, demand_date, ilevel, status, parent,
        avail_row_id, demand_row_id)
      VALUES(  @batch_id, @part, @loc, @avail_qty, @avail_dt, @avail_src, @avail_srcno,
        @demand_src, @demand_srcno, @demand_dt, @level, 'U', @parent, @avail_row, @demand_row)

      UPDATE  #resource_demand
      SET  qty = qty - @avail_qty,
        commit_ed = commit_ed + @avail_qty
      WHERE  row_id = @demand_row

      select @demand_qty = @demand_qty - @avail_qty, @avail_qty = 0
    end -- if (@avail_qty > 0) and (@demand_qty > @avail_qty)

    if (@avail_qty > 0) and (@demand_qty <= @avail_qty)
    --******************************************************************************
    --* We found a supply record which completely satisfies this demand record.
    --* Set the demand record status to (X)Completed so we don't look at it again.
    --* Insert table resource_depends to peg this supply to this demand.
    --* The insert trigger on resource_depends will decrease the qty on the
    --* supply record by the amount needed and the qty on the demand record to 0.
    --* If the demand uses up all of the supply, set the supply status to (X)Completed,
    --* otherwise leave it as 'N' so we find it again if there is any more demand
    --* for this part/location. 
    --******************************************************************************
    begin
      UPDATE  #resource_demand
      SET  status  = 'X',
        qty = 0,
        commit_ed = commit_ed + @demand_qty
      WHERE  row_id  = @demand_row

      UPDATE #resource_avail
      SET  status    =  case when @demand_qty = @avail_qty then 'X' else status end,
        qty = qty - @demand_qty,
        commit_ed = commit_ed + @demand_qty
      WHERE  row_id     = @avail_row 

      INSERT  resource_depends(
        batch_id, part_no, location, qty, avail_date, avail_source, avail_source_no,
        demand_source, demand_source_no, demand_date, ilevel, status, parent,
        avail_row_id, demand_row_id)
      VALUES(  @batch_id, @part, @loc, @demand_qty, @avail_dt, @avail_src, @avail_srcno,
        @demand_src, @demand_srcno, @demand_dt, @level, 'F', @parent, @avail_row, @demand_row)

      select @demand_qty = 0, @avail_qty = @avail_qty - @demand_qty
      CONTINUE
    end -- if (@avail_qty > 0) and (@demand_qty <= @avail_qty)

    FETCH c_res_avail INTO @avail_row, @avail_qty, @avail_dt, @avail_src, @avail_srcno
  end

  CLOSE c_res_avail
  DEALLOCATE c_res_avail

  if @demand_qty > 0
  --******************************************************************************
  --* We did not find any supply to satisfy any part of this demand.
  --* If it's not a (P)urchase item, then we'll check later to see if a build plan
  --* exists, so set the status of the demand to (U)nfilled.  If the item
  --* is a (P)urchase item, then consider it an end item which means that we can't
  --* fill this demand so set the status to (X)Completed.
  --******************************************************************************
  begin
    UPDATE  #resource_demand
    SET  status  = case when @ptype = 'P' then 'X' else 'U' end,
      qty = qty + case when source = 'M'  and max_stock > min_stock then max_stock - min_stock else 0 end
    WHERE  row_id  = @demand_row
  end -- if @avail_qty = 0

 
  --******************************************************************************
  --* Get next demand record
  --******************************************************************************
  FETCH c_res_demand INTO @loc, @part, @demand_qty, @demand_dt, @demand_src,
    @demand_srcno, @level, @parent, @ptype, @demand_row
end -- while @demand_row > 0

CLOSE c_res_demand
DEALLOCATE c_res_demand

return
GO
GRANT EXECUTE ON  [dbo].[fs_sch_step1] TO [public]
GO
