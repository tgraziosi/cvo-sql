SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_operation]
@mode char(2),
@sched_operation_id int = 0,
@sched_process_id int = NULL,
@operation_step int = NULL,
@location varchar(10) = NULL,
@ave_flat_qty float = 0,
@ave_unit_qty float = 0,
@ave_wait_qty float = 0,
@ave_flat_time float = 0,
@ave_unit_time float = 0,
@operation_type char(1) = 'M',
@complete_qty float = 0,
@discard_qty float = 0,
@operation_status char(1) = 'U',
@work_datetime datetime = NULL,
@done_datetime datetime = NULL,
@scheduled_duration float = NULL
as
begin
    declare @sched_id int

  if @mode = 'I'
  begin
    Insert sched_operation 
      (sched_process_id,operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,ave_unit_time,operation_type,complete_qty,discard_qty,operation_status,work_datetime,done_datetime,scheduled_duration)
    values
      (@sched_process_id,@operation_step,@location,@ave_flat_qty,@ave_unit_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type,@complete_qty,@discard_qty,@operation_status,@work_datetime,@done_datetime,@scheduled_duration)
 
    return @@identity
  end
  if @mode = 'U1'
  begin
    update sched_operation
    set operation_status = @operation_status,
      ave_flat_time = @ave_flat_time, 
      ave_unit_time = @ave_unit_time,
      work_datetime = @work_datetime,
      done_datetime = @done_datetime,
      scheduled_duration = @scheduled_duration
      WHERE sched_operation_id = @sched_operation_id

    return @@rowcount
  end
  if @mode = 'D1'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOP
      from sched_operation_plan SOP, sched_operation SO where SOP.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = @sched_process_id
      delete SOR
      from sched_operation_resource SOR, sched_operation SO where SOR.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = @sched_process_id
      delete SOI
      from sched_operation_item SOI, sched_operation SO where SOI.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = @sched_process_id
    end
    delete sched_operation where sched_process_id = @sched_process_id

    return @@rowcount
  end
  if @mode = 'DP'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOP
      from sched_operation_plan SOP, sched_operation SO where SOP.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = @sched_process_id and operation_step = @operation_step
      delete SOR
      from sched_operation_resource SOR, sched_operation SO where SOR.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = @sched_process_id and operation_step = @operation_step
      delete SOI
      from sched_operation_item SOI, sched_operation SO where SOI.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = @sched_process_id and operation_step = @operation_step
    end
    delete sched_operation where sched_process_id = @sched_process_id and operation_step = @operation_step

    return @@rowcount
  end
  if @mode = 'DA'
  begin
    select @sched_id = @sched_process_id

    if (@@version like '%7.0%')
    begin
      delete SOP
      from sched_operation_plan SOP, sched_operation SO, sched_process SP where SOP.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id
      delete SOR
      from sched_operation_resource SOR, sched_operation SO, sched_process SP where SOR.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id
      delete SOI
      from sched_operation_item SOI, sched_operation SO, sched_process SP where SOI.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id
    end

    delete SO
    from sched_operation SO
    join sched_process SP on SP.sched_process_id = SO.sched_process_id
    where SP.sched_id = @sched_id

    return @@rowcount
  end
  if @mode = 'DC'
  begin
    select @sched_id = @sched_process_id

    if (@@version like '%7.0%')
    begin
      delete SOP
      from sched_operation_plan SOP, sched_operation SO, sched_process SP where SOP.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id and SP.source_flag = 'P'
      delete SOR
      from sched_operation_resource SOR, sched_operation SO, sched_process SP where SOR.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id and SP.source_flag = 'P'
      delete SOI
      from sched_operation_item SOI, sched_operation SO, sched_process SP where SOI.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id and SP.source_flag = 'P'
    end

    delete SO
    from sched_operation SO
    join sched_process SP on SP.sched_process_id = SO.sched_process_id
    where SP.sched_id = @sched_id and SP.source_flag = 'P'

    return @@rowcount
  end
  if @mode = 'DL'
  begin
    select @sched_id = @sched_process_id

    if (@@version like '%7.0%')
    begin
      delete SOP
      from sched_operation_plan SOP, sched_operation SO, sched_process SP where SOP.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id and SO.location = @location
      delete SOR
      from sched_operation_resource SOR, sched_operation SO, sched_process SP where SOR.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id and SO.location = @location
      delete SOI
      from sched_operation_item SOI, sched_operation SO, sched_process SP where SOI.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id and SP.sched_id = @sched_id and SO.location = @location
    end

    delete SO
    from sched_operation SO
    join sched_process SP on SP.sched_process_id = SO.sched_process_id
    where SP.sched_id = @sched_id and SO.location = @location

    return @@rowcount
  end

end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_operation] TO [public]
GO
