SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_forecast]
	(
	@sched_id	INT,
        @first_call	INT,
	@sched_location varchar(10),
        @forecast_resync_flag   CHAR(1),
        @forecast_delete_past_flag CHAR(1),
        @forecast_horizon       INT,
        @forecast_min_date      DATETIME,
        @forecast_max_date      DATETIME,
	@order_priority_id	INT,
        @apply_changes  INT = 0
	)
AS
BEGIN


DECLARE @err_ind		INT,
	@sched_order_id		INT

SET NOCOUNT ON

if @forecast_resync_flag = 'Y' and @first_call = -1
begin
  select @err_ind = 0

CREATE TABLE #temp_inv_forecast (
  inv_forecast_location        VARCHAR(10) NOT NULL,
  inv_forecast_part_no         VARCHAR(30) NOT NULL,
  inv_forecast_demand_date     DATETIME NOT NULL,
  inv_forecast_qty             FLOAT NOT NULL
)

  --------------------------------------------------------------------------------------------------------------
  -- The temp table will contain the valid forecast as of today based on:
  --   - Whether or not we are deleting past-due and
  --   - The length of our forecast horizon.
  -----------------------------------------------------------------------------------------------------------
  INSERT #temp_inv_forecast(inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date,inv_forecast_qty)
  SELECT FS.LOCATION,FP.PART_NO, FT.FIRST_DAY, (FF.FORECAST + FF.ADJUSTMENT)
  FROM EFORECAST_LOCATION FS 
  JOIN EFORECAST_TIME FT on FT.FIRST_DAY >= @forecast_min_date
    AND FT.FIRST_DAY <= @forecast_max_date
  JOIN EFORECAST_FORECAST FF on FF.LOCATIONID = FS.LOCATIONID and FF.TIMEID = FT.TIMEID and FF.SESSIONID IN
    (SELECT DISTINCT FS1.SESSIONID FROM EFORECAST_LOCATION FS1 WHERE FS1.LOCATION IN
      (select location from #sched_locations))
  JOIN EFORECAST_PRODUCT FP on FP.PRODUCTID = FF.PRODUCTID
  WHERE FS.LOCATION in (select location from #sched_locations) and (FF.FORECAST + FF.ADJUSTMENT) != 0
  if @@error <> 0   select @err_ind = 1


  INSERT #temp_inv_forecast(inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date,inv_forecast_qty)
  SELECT FS.LOCATION,FP.PART_NO, FT.FIRST_DAY, FF.QTY 
  FROM EFORECAST_LOCATION FS 
  JOIN EFORECAST_TIME FT on FT.FIRST_DAY >= @forecast_min_date
    AND FT.FIRST_DAY <= @forecast_max_date
  JOIN EFORECAST_CUSTOMER_FORECAST FF on FF.LOCATIONID = FS.LOCATIONID and FF.TIMEID = FT.TIMEID 
  JOIN EFORECAST_PRODUCT FP on FP.PRODUCTID = FF.PRODUCTID
  WHERE FS.LOCATION in (select location from #sched_locations) and FF.QTY != 0
  if @@error <> 0   select @err_ind = 1

  INSERT #inv_forecast(inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date,inv_forecast_qty)
  select inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date,sum(inv_forecast_qty)
  from #temp_inv_forecast
  group by inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date
  if @@error <> 0   select @err_ind = 1


  return @err_ind
end


if @forecast_resync_flag = 'Y'
BEGIN
  -- Look for removed or expired forecast.
  select @err_ind = 0
  if @apply_changes = 1 
  begin
    DECLARE schedforecast CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
    SELECT distinct sched_order_id 
    FROM sched_order SO
    WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F' and SO.location = @sched_location	-- mls 3/22/02 SCR 28558
    AND NOT EXISTS( SELECT 1 FROM #inv_forecast INVF 
      WHERE INVF.inv_forecast_location = SO.location AND  INVF.inv_forecast_part_no = SO.part_no AND
      INVF.inv_forecast_demand_date = SO.done_datetime)

    OPEN schedforecast
    FETCH NEXT FROM schedforecast into @sched_order_id

    While @@FETCH_STATUS = 0
    begin									-- mls #22 end
      exec adm_set_sched_order 'D',NULL,@sched_order_id
      if @@error <> 0  select @err_ind = @err_ind + 1

      FETCH NEXT FROM schedforecast into @sched_order_id
    end
    CLOSE schedforecast
    DEALLOCATE schedforecast
  end

  if @err_ind != 0 or @apply_changes = 0
  begin
    INSERT #result (object_flag,status_flag,location,part_no,forecast_demand_date,sched_order_id,message)
    SELECT distinct 'F','X',SO.location,SO.part_no,SO.done_datetime,SO.sched_order_id,'Forecast Past-Due, Past Horizon, or Deleted: ' + SO.location + '/' + SO.part_no + ' ' + LTRIM(STR(MONTH(SO.done_datetime))) + '/' + LTRIM(STR(DAY(SO.done_datetime))) + '/' + LTRIM(STR(YEAR(SO.done_datetime)))
    FROM sched_order SO
    WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F' and SO.location = @sched_location	-- mls 3/22/02 SCR 28558
    AND NOT EXISTS( SELECT 1 FROM #inv_forecast INVF 
      WHERE INVF.inv_forecast_location = SO.location AND  INVF.inv_forecast_part_no = SO.part_no AND
      INVF.inv_forecast_demand_date = SO.done_datetime)
  end

  -- Look for forecast with quantity changed
  select @err_ind = 0
  if @apply_changes = 1
  begin
    UPDATE sched_order 
    SET uom_qty = INVF.inv_forecast_qty 
    FROM sched_order SO
    JOIN #inv_forecast INVF on INVF.inv_forecast_location = SO.location AND INVF.inv_forecast_part_no = SO.part_no 
      AND INVF.inv_forecast_demand_date = SO.done_datetime AND INVF.inv_forecast_qty != SO.uom_qty
    WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F' and SO.location = @sched_location 
    if @@error <> 0  select @err_ind = @err_ind + 1
  end
  
  if @apply_changes = 0 or @err_ind != 0
  begin
    INSERT #result (object_flag,status_flag,location,part_no,forecast_demand_date,forecast_qty,sched_order_id,message)
    SELECT distinct 'F','C',SO.location,SO.part_no,SO.done_datetime,INVF.inv_forecast_qty,SO.sched_order_id,'Forecast Qty Changed:' + SO.location + '/' + SO.part_no + '' + LTRIM(STR(MONTH(SO.done_datetime))) + '/' + LTRIM(STR(DAY(SO.done_datetime))) + '/' + LTRIM(STR(YEAR(SO.done_datetime)))
    FROM sched_order SO
    JOIN #inv_forecast INVF on INVF.inv_forecast_location = SO.location AND INVF.inv_forecast_part_no = SO.part_no 
      AND INVF.inv_forecast_demand_date = SO.done_datetime AND INVF.inv_forecast_qty != SO.uom_qty
    WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F' and SO.location = @sched_location
  end

  -- Look for new forecast
  select @err_ind = 0
  if @apply_changes = 1
  begin
    INSERT sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,action_flag)
    SELECT @sched_id, @sched_location, INVF.inv_forecast_demand_date, INVF.inv_forecast_part_no,
      INVF.inv_forecast_qty, IM.uom, @order_priority_id, 'F','?'
    FROM #inv_forecast INVF
    LEFT OUTER JOIN inv_master IM on IM.part_no = INVF.inv_forecast_part_no
    WHERE INVF.inv_forecast_location = @sched_location 
      AND NOT EXISTS( SELECT 1 FROM sched_order SO WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F' 
      AND INVF.inv_forecast_location = SO.location AND INVF.inv_forecast_part_no = SO.part_no 
      AND INVF.inv_forecast_demand_date = SO.done_datetime)
    if @@error <> 0  select @err_ind = @err_ind + 1
  end

  if @apply_changes = 0 or @err_ind != 0
  begin
    INSERT #result (object_flag,status_flag,location,part_no,forecast_demand_date,forecast_qty,message,forecast_uom)
    SELECT distinct 'F','N',INVF.inv_forecast_location,INVF.inv_forecast_part_no,INVF.inv_forecast_demand_date,
      INVF.inv_forecast_qty,'New Forecast:' + INVF.inv_forecast_location + '/' + INVF.inv_forecast_part_no + ' ' + LTRIM(STR(MONTH(INVF.inv_forecast_demand_date))) + '/' + LTRIM(STR(DAY(INVF.inv_forecast_demand_date))) + '/' + LTRIM(STR(YEAR(INVF.inv_forecast_demand_date))),
      IM.uom
    FROM #inv_forecast INVF
    LEFT OUTER JOIN inv_master IM on IM.part_no = INVF.inv_forecast_part_no
    WHERE INVF.inv_forecast_location = @sched_location 
      AND NOT EXISTS( SELECT 1 FROM sched_order SO WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F' 
          AND INVF.inv_forecast_location = SO.location AND INVF.inv_forecast_part_no = SO.part_no 
          AND INVF.inv_forecast_demand_date = SO.done_datetime)
  end
END
else										-- mls 7/30/01 SCR 27313 start
BEGIN
  if @forecast_delete_past_flag = 'Y' and @first_call = 1
  begin
    -- Look for removed or expired forecast.
    select @err_ind = 0
    if @apply_changes = 1 
    begin
      DECLARE schedforecast CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
      SELECT distinct sched_order_id 
      FROM sched_order SO
      WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F'  and SO.done_datetime < getdate()

      OPEN schedforecast
      FETCH NEXT FROM schedforecast into @sched_order_id

      While @@FETCH_STATUS = 0
      begin									-- mls #22 end
        exec adm_set_sched_order 'D',NULL,@sched_order_id
        if @@error <> 0  select @err_ind = @err_ind + 1

        FETCH NEXT FROM schedforecast into @sched_order_id
      end
      CLOSE schedforecast
      DEALLOCATE schedforecast
    end

    if @apply_changes = 0 or @err_ind != 0
    begin
      INSERT #result (object_flag,status_flag,location,part_no,forecast_demand_date,sched_order_id,message)
      SELECT 'F','X',SO.location,SO.part_no,SO.done_datetime,SO.sched_order_id,'Forecast Past-Due: ' + SO.location + '/' + SO.part_no + ' ' + LTRIM(STR(MONTH(SO.done_datetime))) + '/' + LTRIM(STR(DAY(SO.done_datetime))) + '/' + LTRIM(STR(YEAR(SO.done_datetime)))
      FROM sched_order SO
      WHERE SO.sched_id = @sched_id AND SO.source_flag = 'F'  and SO.done_datetime < getdate()
    end
  end
END										-- mls 7/30/01 SCR 27313 end

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_forecast] TO [public]
GO
