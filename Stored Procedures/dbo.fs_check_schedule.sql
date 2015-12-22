SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_check_schedule]
	(
	@sched_id       INT
	)
AS
BEGIN
DECLARE @rowcount       	INT,
	@so_action_flag char(1), 
	@so_action_datetime datetime,
	@uom_qty              FLOAT,
        @order_id_pulling    INT,
        @work_datetime_pulled    DATETIME,
        @uom_tot_qty_pulled     FLOAT,
        @uom_inv_qty_pulled     FLOAT,
        @order_action_flag      CHAR(1),
        @replenishment_level   	INT,
        @order_action_datetime  DATETIME,
        @lower_level_action_datetime DATETIME,
        @lower_level_action_flag     CHAR(1),
        @replenishment_table_ctr       INT,
        @next_replenishment_level      INT,
	@work_info_pulled varchar(40), 
	@make_pulled char(1),
	@lower_level_action_info varchar(40)


CREATE TABLE #replenishments
	(
	sched_order_id		INT,
        replenishment_level     INT,
        pulled_process_id       INT NULL,
        pulled_source_flag      CHAR(1),
        pulled_work_datetime    DATETIME NULL,
        pulled_item_id          INT NULL,
	)

create index #repl1 on #replenishments(replenishment_level, pulled_process_id)

select     @replenishment_level = 1,
  @replenishment_table_ctr = 0

INSERT #replenishments (
  sched_order_id,
  replenishment_level,
  pulled_process_id,
  pulled_source_flag,
  pulled_work_datetime)
SELECT SO.sched_order_id, @replenishment_level,SI.sched_process_id,SI.source_flag,
  SCO.work_datetime
FROM sched_item SI
JOIN sched_order_item SOI on SOI.sched_item_id = SI.sched_item_id
JOIN sched_order SO on SO.sched_order_id = SOI.sched_order_id
join sched_operation SCO on SCO.sched_process_id = SI.sched_process_id and 
  SCO.operation_step = 1 and SI.source_flag = 'M'
WHERE SI.sched_id = @sched_id 

SELECT @rowcount = @@rowcount
SELECT @replenishment_table_ctr = @replenishment_table_ctr + 1
WHILE @rowcount > 0
BEGIN
  SELECT @next_replenishment_level = @replenishment_level + 1
  -- For the process we added to the #replenishments table above, find all processes that it is 
  -- dependent on and determine when those processes begin.
  INSERT #replenishments
    (sched_order_id,
    replenishment_level,
    pulled_process_id,
    pulled_source_flag,
    pulled_work_datetime,
    pulled_item_id)
  SELECT R.sched_order_id,
    @next_replenishment_level,
    case when SI.source_flag = 'M' then SI.sched_process_id else NULL end, 
    SI.source_flag, 
    case when SI.source_flag = 'M' then isnull(SO2.work_datetime,SI.done_datetime)
    when SI.source_flag = 'P' then isnull(SP.lead_datetime,SI.done_datetime)
    else SI.done_datetime end,
    SI.sched_item_id
  from #replenishments R
  join sched_operation SO1 on SO1.sched_process_id = R.pulled_process_id 
  join sched_operation_item SOI on SOI.sched_operation_id = SO1.sched_operation_id
  join sched_item SI on SI.sched_item_id = SOI.sched_item_id
    and SI.sched_id = @sched_id and SI.source_flag between 'M' and 'R'
  left outer join sched_operation SO2 on SO2.sched_process_id = SI.sched_process_id
    and SO2.operation_step = 1 
  left outer join sched_purchase SP on SP.sched_item_id = SI.sched_item_id
  where R.replenishment_level = @replenishment_level and SI.source_flag in ('M','P','O','R') 

  -- if rows were added, it means this process is dependent on other process or planned purchases
  SELECT @rowcount = @@rowcount
  IF @rowcount > 0
  BEGIN
    SELECT @replenishment_table_ctr = @replenishment_table_ctr + @rowcount
    SELECT @replenishment_level = @replenishment_level + 1
  END
END

-- Get all the order pulls from inv_list
DECLARE c_order_top_level_pulls CURSOR STATIC READ_ONLY FORWARD_ONLY FOR
SELECT SO.sched_order_id, SO.uom_qty, SO.action_flag,SO.action_datetime ,
  sum(SOI.uom_qty),
  sum(case when SI.source_flag = 'I' then SOI.uom_qty else 0 end),
  case when SO.uom_qty > sum(SOI.uom_qty) then NULL else 
    min(case SI.source_flag 
      when 'P' then convert(varchar(20),SP.lead_datetime,120) + '~P'
      when 'O' then convert(varchar(20),SI.done_datetime,120) + '~O'
      when 'R' then convert(varchar(20),SI.done_datetime,120) + '~R'
      else '2499-12-31 00:00:00~Z' end) 
  end,
  max(case when SI.source_flag = 'M' then 'M' else '' end)
FROM sched_item SI
JOIN sched_order_item SOI on SI.sched_item_id = SOI.sched_item_id
JOIN sched_order SO on SO.sched_order_id = SOI.sched_order_id
left outer join sched_operation SCO on SCO.sched_process_id = SI.sched_process_id and 
  SCO.operation_step = 1 
left outer join sched_purchase SP on SP.sched_item_id = SI.sched_item_id 
WHERE SI.sched_id = @sched_id AND SI.source_flag between 'I' and 'R' and
((SI.source_flag = 'M'  and SCO.sched_process_id is not null)
or (SI.source_flag = 'P' and SP.sched_item_id is not null)
or (SI.source_flag in ('I','O','R')) )
group by SO.sched_order_id, SO.uom_qty,SO.action_flag,SO.action_datetime 

OPEN c_order_top_level_pulls

IF @@cursor_rows > 0
BEGIN -- Begin 1
  FETCH c_order_top_level_pulls INTO @order_id_pulling,@uom_qty,
    @so_action_flag, @so_action_datetime, @uom_tot_qty_pulled,
    @uom_inv_qty_pulled, @work_info_pulled, @make_pulled

  -------------------------------------------------------------------------------------------------
  -- Loop through to determine actions and action datetimes.  If the order is filled or partially
  -- filled by a production, there will be extra work to determine whether the production is dependent
  -- on other productions, etc, etc.
  -------------------------------------------------------------------------------------------------
  WHILE (@@fetch_status = 0)
  BEGIN -- begin 2
    if @work_info_pulled is null
      select @order_action_datetime = NULL, @order_action_flag = 'U'
    else
      select @order_action_datetime = convert(datetime,substring(@work_info_pulled,1,19)),
        @order_action_flag = substring(@work_info_pulled,21,1)
 
    if @order_action_flag != 'U'
    BEGIN
      if @make_pulled = 'M'
      begin
        -- At least a portion was satisfied by released or planned processes.  Determine the earliest dependent date and type.
        SELECT @lower_level_action_info = 
          isnull((select MIN(convert(varchar(20),R.pulled_work_datetime,120) + '~' + R.pulled_source_flag)
          FROM #replenishments R
          where R.sched_order_id = @order_id_pulling and R.pulled_work_datetime is not null),NULL)

        If @lower_level_action_info is not null
        BEGIN
          select @lower_level_action_datetime = convert(datetime,substring(@lower_level_action_info,1,19)),
            @lower_level_action_flag = substring(@lower_level_action_info,21,1)

          IF @lower_level_action_datetime < @order_action_datetime
          BEGIN
            SELECT @order_action_datetime = @lower_level_action_datetime,
              @order_action_flag = @lower_level_action_flag
          END
        END
        ELSE
        BEGIN
          IF @uom_inv_qty_pulled >= @uom_tot_qty_pulled
          BEGIN
            SELECT @order_action_datetime = NULL,
              @order_action_flag = 'I'
          END
        END
      END
      ELSE
      BEGIN
        IF @uom_inv_qty_pulled >= @uom_tot_qty_pulled
        BEGIN
          SELECT @order_action_datetime = NULL,
            @order_action_flag = 'I'
        END
      END
    END
    ---------------------------------------------------------------------------------------------------------------------------
    -- If not all pulled from inv_list and none was pulled from processes, then it must have been satisfied only from planned,
    -- released, or on-order purchases.  If so, @order_action_datetime and @order_action_flag have already been set above.
    ---------------------------------------------------------------------------------------------------------------------------
    if @order_action_flag = 'Z'  select @order_action_flag = '?', @order_action_datetime = NULL

    if isnull(@so_action_datetime,'1/1/1900') != isnull(@order_action_datetime,'1/1/1900') or
      isnull(@so_action_flag,'?') != isnull(@order_action_flag,'?')
    begin
      UPDATE sched_order
      SET action_datetime = @order_action_datetime, action_flag = isnull(@order_action_flag,'?')	-- mls 7/9/01 SCR 27161
      FROM sched_order SO
      WHERE SO.sched_id = @sched_id AND SO.sched_order_id = @order_id_pulling
    end

    FETCH c_order_top_level_pulls INTO @order_id_pulling,@uom_qty,
      @so_action_flag, @so_action_datetime, @uom_tot_qty_pulled,
      @uom_inv_qty_pulled, @work_info_pulled, @make_pulled
  END -- end 2
END -- end 1

CLOSE c_order_top_level_pulls
DEALLOCATE c_order_top_level_pulls

DROP TABLE #replenishments

EXEC fs_check_schedule_status @sched_id					-- mls 7/26/01 SCR 27295


UPDATE	sched_model
SET	check_datetime = getdate()
FROM	sched_model SM
WHERE	SM.sched_id = @sched_id

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_check_schedule] TO [public]
GO
