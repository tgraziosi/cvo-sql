SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_build]  @demand_row  int,
        @buyer    varchar(10),
        @location  varchar(10),
        @vendor_no  varchar(12),
        @part_no  varchar(30),
        @category  varchar(10),
        @part_type  varchar(10)    AS



declare  @src    char(1),
   @type    char(1),
   @parent_dt  datetime,        -- demand date of parent item
   @comp_dt  datetime,        -- demand date for component item
   @parent_qty  decimal(20,8),
   @comitted  decimal(20,8),
   @pused    decimal(20,8),
   @level    int,
   @lead    int,
   @batch_id  varchar(20),
   @part    varchar(30),
   @loc    varchar(10),
   @srcno    varchar(20),
   @parent    varchar(30),
   @seq_no    varchar(10),
   @errmsg    varchar(80),
   @tcomp_part varchar(30),
   @ttotal_req decimal(20,8),
   @tcomp_qty decimal(20,8)

--******************************************************************************
--* Get the column values from the demand row that was passed in to this proc
--******************************************************************************
SELECT  @batch_id  = batch_id,
  @part    = part_no,
  @loc    = location,
  @parent_qty  = qty,
  @parent_dt  = demand_date,
  @src    = source,
  @srcno    = source_no,
  @level    = ilevel,
  @parent    = parent,
  @type    = type
FROM  #resource_demand
WHERE  row_id    = @demand_row

--******************************************************************************
--* Prevent an infinite loop caused by a circular reference in the build plans
--******************************************************************************
if @level > 10 begin
   select @errmsg = 'Circular Reference encountered.  Parent: '+@parent+'    Child: '+@part
   RaisError 99998 @errmsg
   Return -1
end

if (NOT EXISTS(  SELECT 1 FROM what_part (nolock) 
  WHERE  asm_no  = @part and ((active  = 'A') or
    (active   = 'B' and @parent_dt < eff_date) or
    (active   = 'U' and @parent_dt >= eff_date)) and
    qty != 0 )
  or exists (select 1 from inv_master (nolock) where part_no = @part and status >= 'P'))	-- mls 10/21/02 SCR 30080
begin
  --**************************************************************************
  --* There is no build plan set up for this item so there is nothing to
  --* explode.  Set the demand row status to (X)Completed and exit.
  --**************************************************************************
  UPDATE  #resource_demand
  SET  status  = 'X'
  WHERE  row_id  = @demand_row

  return 0
end

--******************************************************************************
--* If we get here, then we have demand for a parent item which has component
--* items.  We can satisfy demand for the parent by building it from the
--* components so we need to calculate demand for the components.  First, see if
--* there is a lead time to build the parent, and if so, move up the demand date
--* for the component by this amount.
--******************************************************************************
select @comp_dt = @parent_dt

SELECT @lead = lead_time FROM inv_list (nolock)
WHERE part_no = @part and  location= @loc  

if @lead > 0
begin
  select @comp_dt = DateAdd( day, ( -1 * @lead ), @parent_dt ) 
end

CREATE TABLE  #temp_sch_build(
  tcomp_part  varchar(30),
  ttotal_req  decimal(20,8),
  tcomp_qty  decimal(20,8),
  tseq_no    varchar(10) )

INSERT  #temp_sch_build(tcomp_part, ttotal_req, tcomp_qty, tseq_no)
SELECT  DISTINCT w.part_no, SUM(@parent_qty * w.qty), w.qty, w.seq_no
FROM  what_part w (nolock)
WHERE  w.asm_no  = @part and
  ((w.active  = 'A') or          -- active build plan items 
  (w.active  = 'B' and @parent_dt < w.eff_date) or    -- pending inactive
  (w.active  = 'U' and @parent_dt >= w.eff_date)) and  -- pending active
  w.fixed    != 'Y' and w.qty != 0
GROUP BY w.part_no, w.qty, w.seq_no
having sum(@parent_qty * w.qty) != 0

INSERT  #temp_sch_build(tcomp_part, ttotal_req, tcomp_qty, tseq_no)
SELECT  DISTINCT w.part_no, SUM(w.qty), SUM(w.qty), w.seq_no
FROM  what_part w (nolock)
WHERE  w.asm_no  = @part and
  ((w.active  = 'A') or          -- active build plan items
  (w.active  = 'B' and @parent_dt < w.eff_date) or    -- pending inactive
  (w.active  = 'U' and @parent_dt >= w.eff_date)) and  -- pending active
  w.fixed    = 'Y' and w.qty    != 0
GROUP BY w.part_no, w.seq_no
having sum(w.qty) != 0

--DELETE FROM #temp_sch_build
--WHERE  ttotal_req = 0

--******************************************************************************
--* If there are no rows in the temp table that have a required qty, then 
--* there is no component demand and its doubtful that this item can be built.
--* Set the parent demand row status to (X)Completed so a purchase order gets 
--* suggested and exit this proc.
--******************************************************************************
if not exists (SELECT 1 FROM #temp_sch_build)
begin
  UPDATE  #resource_demand
  SET  status  = 'X'
  WHERE  row_id  = @demand_row

  DROP TABLE #temp_sch_build
  return 0
end

--******************************************************************************
--* If we get here, then we have demand for component items.  First, delete any
--* rows which contain resources or non-qty bearing items. Then, loop through the
--* temp table getting the demand for each component.  It is possible that a row
--* already exists in resource_demand for this component part coming from this 
--* source required on this date.  If so, then add this demand to that row.
--* Otherwise, insert a new row in resource_demand with status (U)nfilled to
--* cover this demand.  Only insert new demand rows for parts which meet the
--* batch selection criteria.
--******************************************************************************
DELETE FROM #temp_sch_build
FROM  inv_list (nolock)
WHERE  #temp_sch_build.tcomp_part  = inv_list.part_no and
  inv_list.location = @loc and inv_list.status    > 'Q'

DECLARE c_temp_sch_build CURSOR LOCAL FOR
SELECT tcomp_part, ttotal_req, tcomp_qty, tseq_no
from #temp_sch_build
order by tseq_no

OPEN c_temp_sch_build

FETCH NEXT FROM c_temp_sch_build INTO 
  @tcomp_part, @ttotal_req, @tcomp_qty, @seq_no

WHILE @@FETCH_STATUS = 0
begin
  if EXISTS(  SELECT  1 FROM  #resource_demand r
    WHERE  r.status  = 'U' and r.part_no  = @tcomp_part and r.source  = @src and
    r.demand_date  = @comp_dt and r.source_no  = @srcno and r.ilevel  = (@level + 1) and
    r.location  = @loc and r.parent  = @part)
  begin
    UPDATE  #resource_demand
    SET  qty = qty + @ttotal_req
    WHERE  status  = 'U' and part_no  = @tcomp_part and source  = @src and
      demand_date  = @comp_dt and source_no  = @srcno and ilevel  = (@level + 1) and
      location  = @loc and parent  = @part
  end -- if EXISTS
  else
  begin
    INSERT  #resource_demand( batch_id, part_no, qty, demand_date, ilevel,
      location, source, status, commit_ed, source_no, parent, pqty, p_used,
      type, vendor, uom, buyer, prod_no, location2)
    SELECT  @batch_id, @tcomp_part, @ttotal_req, @comp_dt, (@level + 1),
      @loc, @src, 'U', 0, @srcno, @part, @tcomp_qty, 0, t.type, t.vendor,
      t.uom, t.buyer, 0, @loc
    FROM  #resource_demand t
    WHERE  t.part_no = @tcomp_part and t.location  = @loc and t.source = 'T'
  end -- else

  --**************************************************************************
  --* Get the next record
  --**************************************************************************
  FETCH NEXT FROM c_temp_sch_build INTO 
    @tcomp_part, @ttotal_req, @tcomp_qty, @seq_no
end -- while @seq_no > ''

CLOSE c_temp_sch_build
DEALLOCATE c_temp_sch_build

DROP TABLE #temp_sch_build

--******************************************************************************
--* We have now calculated the demand for the components.  We still have the 
--* (U)filled demand for the parent.  If the parent is a Purchase Outsource item 
--* (type = Q), then we still need to suggest a purchase order for it, so set the
--* status of the row to (X)Completed so the unfilled quantity will get grouped
--* into a suggested PO.  Otherwise, the assumption is that this demand will be
--* filled by a work order which will build the parent from the components. We
--* set the status of the parent demand row to (P)arent to signify that we are 
--* done with it but we don't want to include the demand qty in a suggested 
--* purchase order.  First we check to see if there is already a (P)arent demand
--* row for this part number coming from the same source and date.  If so, add
--* this "built" demand to that row and delete the current row, otherwise just
--* update the status.
--******************************************************************************
if (@type != 'Q' and
  EXISTS(  SELECT 1 FROM #resource_demand 
  WHERE  part_no    = @part and location  = @loc and source_no  = @srcno and
    demand_date  = @parent_dt and source    = @src and ilevel    = @level and
    status    = 'P' and parent    = @parent ) )
begin
  SELECT  @comitted  = commit_ed,
    @pused    = p_used
  FROM  #resource_demand
  WHERE  row_id    = @demand_row

  UPDATE  #resource_demand
  SET  commit_ed  = commit_ed + @comitted,
    p_used    = p_used + @pused,
    qty    = qty + @parent_qty
  FROM  #resource_demand
  WHERE  part_no    = @part and location  = @loc and source_no  = @srcno and
    demand_date  = @parent_dt and source    = @src and ilevel    = @level and
    status    = 'P' and parent    = @parent 

  DELETE #resource_demand
  WHERE row_id = @demand_row
end
else
begin
  UPDATE  #resource_demand
  SET  status  = (case when @type = 'Q' then 'X' else 'P' end)
  WHERE  row_id  = @demand_row
end

return 1


GO
GRANT EXECUTE ON  [dbo].[fs_sch_build] TO [public]
GO
