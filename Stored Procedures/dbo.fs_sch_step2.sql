SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_step2] @batch_id varchar(20)    AS



declare  @demand_src    char(1),
  @avail_src    char(1),
   @demand_dt    datetime,
  @avail_dt    datetime,
   @demand_qty    decimal(20,8),
  @avail_qty    decimal(20,8),
  @comitted    decimal(20,8),
   @retval      int,
  @demand_row    int,
  @avail_row    int,
  @current_level  int,
  @level      int,
   @loc      varchar(10),
  @part      varchar(30),
  @demand_srcno  varchar(20),
  @avail_srcno  varchar(20),
  @parent      varchar(30),
  @buyer      varchar(10),      -- batch selection criteria
  @location    varchar(10),      -- batch selection criteria
  @vendor_no    varchar(12),      -- batch selection criteria
  @part_no    varchar(30),      -- batch selection criteria
  @category    varchar(10),      -- batch selection criteria
  @part_type    varchar(10)      -- batch selection criteria

--******************************************************************************
--* Obtain the batch selection criteria for which items to include in the
--*  calculation.  We need this info to pass in to fs_sch_build since it inserts
--* new demand rows into resource_demand.  
--******************************************************************************
SELECT  @buyer      = IsNull(buyer, '%'),
  @location    = IsNull(location, '%'),
  @vendor_no    = IsNull(vendor_no, '%'),
  @part_no    = IsNull(part_no, '%'),
  @category    = IsNull(category, '%'),
  @part_type    = IsNull(part_type, '%')
FROM  resource_batch
WHERE  batch_id = @batch_id

--******************************************************************************
--* Determine what level we have exploded to so far
--******************************************************************************
select @current_level = (SELECT MAX(ilevel) FROM #resource_demand)

--******************************************************************************
--* Get the first (U)nfilled demand row at the current build-plan level
--******************************************************************************
DECLARE c_res_demand CURSOR LOCAL FOR
SELECT row_id, location, part_no, qty, demand_date, source, source_no, ilevel,
  parent
from #resource_demand
  WHERE status = 'U' and ilevel = @current_level and qty > 0
order by demand_date, row_id					-- mls 5/30/02 SCR 29003

OPEN c_res_demand

FETCH NEXT FROM c_res_demand into
  @demand_row, @loc, @part, @demand_qty, @demand_dt, @demand_src, @demand_srcno,
  @level, @parent

while @@FETCH_STATUS = 0
begin
  select @avail_qty = 0, @avail_row = 0

  --**************************************************************************
  --* Look in resource_avail for supply for this part number in this location.
  --* Get the first record with uncommitted supply available and that
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
    --**************************************************************************
    --* We found some supply, but it is not enough to satisfy the demand coming from
    --* this demand record.  Set the supply record status to (X)Completed so we don't
    --* look at it again.  Insert table resource_depends to peg this supply to this
    --* demand.  The insert trigger on resource_depends will decrease the qty on the  
    --* supply record to 0 and the qty on the demand record to the remainder qty 
    --* which still needs to be filled.  We leave the status of the demand record in
    --* resource_demand unchanged so that it will come up again next time through 
    --* the loop.
    --**************************************************************************
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
    --**************************************************************************
    --* We found a supply record which completely satisfies this demand record.
    --* If the demand uses up all of the supply, set the supply status to
    --* (X)Completed, otherwise leave it as 'N' so we find it again if there is
    --* any more demand for this part/location.
    --* Insert table resource_depends to peg this supply to this demand.
    --* The insert trigger on resource_depends will decrease the qty on the
    --* supply record by the amount needed and the qty on the demand record to 0. 
    --* Check to see if we already have a (F)illed demand record for this
    --* part/location/source at this level on this date.  If yes, add this demand
    --* to that row, otherwise set the demand record status to (F)illed so we
    --* don't look at it again.
    --**************************************************************************
    begin
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

      if EXISTS (  SELECT 1 FROM #resource_demand
        WHERE  part_no    = @part and location  = @loc and demand_date  = @demand_dt and
          source    = @demand_src and source_no  = @demand_srcno and ilevel = @level and
          parent    = @parent and status    = 'F' )
      begin
        --******************************************************************
        --* Select these values here since inserting resource_depends will
        --* have changed them.
        --******************************************************************
        SELECT  @demand_qty  = @demand_qty + commit_ed
        FROM  #resource_demand
        WHERE  row_id    = @demand_row

        UPDATE  #resource_demand
        SET commit_ed  = commit_ed + @demand_qty
        WHERE  part_no    = @part and location  = @loc and demand_date  = @demand_dt and
          source    = @demand_src and source_no  = @demand_srcno and ilevel = @level and
          parent    = @parent and status    = 'F' 

        DELETE  #resource_demand
        WHERE  row_id = @demand_row
      end
      else
      begin
        UPDATE  #resource_demand
        SET  status  = 'F',
          qty = 0,
          commit_ed = commit_ed + @demand_qty
        WHERE  row_id  = @demand_row
      end -- if EXISTS
  
      select @demand_qty = 0, @avail_qty = @avail_qty - @demand_qty
      CONTINUE
    end -- if (@avail_qty > 0) and (@demand_qty <= @avail_qty)
  
    FETCH c_res_avail INTO @avail_row, @avail_qty, @avail_dt, @avail_src, @avail_srcno
  end

  CLOSE c_res_avail
  DEALLOCATE c_res_avail

  if @demand_qty > 0
  --**************************************************************************
  --* We did not find any supply to satisfy any part of this demand so call
  --* fs_sch_build.  This procedure will either explode the item if a build
  --* plan exists for it or set the status to (X)Completed so that a purchase
  --* order gets suggested.
  --**************************************************************************
  begin
    EXEC @retval = fs_sch_build @demand_row, @buyer, @location, @vendor_no,
        @part_no, @category, @part_type
  end -- if @demand_row > 0

  --******************************************************************************
  --* Get next demand record
  --******************************************************************************
  FETCH NEXT FROM c_res_demand into
    @demand_row, @loc, @part, @demand_qty, @demand_dt, @demand_src, @demand_srcno,
    @level, @parent
end -- while @demand_row > 0

CLOSE c_res_demand
DEALLOCATE c_res_demand


GO
GRANT EXECUTE ON  [dbo].[fs_sch_step2] TO [public]
GO
