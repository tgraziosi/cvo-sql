SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_item]
@mode char(2),
@sched_id int = NULL,
@sched_item_id int = 0,
@location varchar(10) = NULL,
@part_no varchar(30) = NULL,
@done_datetime datetime = NULL,
@uom_qty float = NULL,
@uom char(2) = NULL,
@source_flag char(1) = NULL,
@sched_process_id int = NULL,
@sched_transfer_id int = NULL,
@lead_datetime datetime = NULL,
@status_flag char(1) = NULL,
@sched_order_id int = NULL
as
begin
  Declare @SIidentity int

  if @mode = 'I'
  begin
    Insert sched_item
      (sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_process_id,sched_transfer_id)
    values
      (@sched_id,@location,@part_no,@done_datetime,@uom_qty,@uom,@source_flag,@sched_process_id,@sched_transfer_id)

    return @@identity
  end
  if @mode = 'IP'
  begin
    Insert sched_item
      (sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_process_id,sched_transfer_id)
    values
      (@sched_id,@location,@part_no,@done_datetime,@uom_qty,@uom,@source_flag,@sched_process_id,@sched_transfer_id)

    select @SIidentity = @@identity

    INSERT sched_purchase (sched_item_id,lead_datetime,status_flag,sched_order_id)
    values (@SIidentity, @lead_datetime,@status_flag,@sched_order_id)

    return @SIidentity
  end
  if @mode = 'D'
  begin
    if (@@version like '%7.0%')
    begin
      delete sched_order_item where sched_item_id = @sched_item_id
      delete sched_operation_item where sched_item_id = @sched_item_id
      delete sched_transfer_item where sched_item_id = @sched_item_id
      delete sched_purchase where sched_item_id = @sched_item_id
    end
    delete sched_item where sched_item_id = @sched_item_id
 
    return @@rowcount
  end
  if @mode = 'DT'
  begin
    if exists (select 1 from sched_item where sched_item_id = @sched_item_id and source_flag = 'T')
    begin
    if (@@version like '%7.0%')
    begin
      delete sched_order_item where sched_item_id = @sched_item_id
      delete sched_operation_item where sched_item_id = @sched_item_id
      delete sched_transfer_item where sched_item_id = @sched_item_id
      delete sched_purchase where sched_item_id = @sched_item_id
    end
      delete sched_item where sched_item_id = @sched_item_id
      return @@rowcount
    end
    return 0
  end
  if @mode = 'DU'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = @sched_transfer_id
      delete SOI 
      from sched_operation_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = @sched_transfer_id
      delete STI 
      from sched_transfer_item STI, sched_item SI where STI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = @sched_transfer_id
      delete SP
      from sched_purchase SP, sched_item SI where SP.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = @sched_transfer_id
    end

      delete sched_item where sched_transfer_id = @sched_transfer_id
      return @@rowcount

  end
  if @mode = 'D1'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = @sched_process_id
      delete SOI 
      from sched_operation_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = @sched_process_id
      delete STI 
      from sched_transfer_item STI, sched_item SI where STI.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = @sched_process_id
      delete SP
      from sched_purchase SP, sched_item SI where SP.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = @sched_process_id
    end
    delete from sched_item
    where sched_process_id = @sched_process_id

    return @@rowcount
  end
  if @mode = 'DA'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id
      delete SOI 
      from sched_operation_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id
      delete STI 
      from sched_transfer_item STI, sched_item SI where STI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id
      delete SP
      from sched_purchase SP, sched_item SI where SP.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id
    end
    delete from sched_item
    where sched_id = @sched_id

    return @@rowcount
  end
  if @mode = 'DC' or @mode = 'DE'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.source_flag between 'M' and 'P'
      and SI.source_flag in ('M','P')
      delete SOI 
      from sched_operation_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.source_flag between 'M' and 'P'
      and SI.source_flag in ('M','P')
      delete STI 
      from sched_transfer_item STI, sched_item SI where STI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.source_flag between 'M' and 'P'
      and SI.source_flag in ('M','P')
      delete SP
      from sched_purchase SP, sched_item SI where SP.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.source_flag between 'M' and 'P'
      and SI.source_flag in ('M','P')
    end

    DELETE	sched_item
    where sched_id = @sched_id and source_flag between 'M' and 'P'
    and source_flag in ('M','P')

    return @@rowcount
  end
  if @mode = 'DD' or @mode = 'DE'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI, sched_transfer ST where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.source_flag = 'P' and ST.sched_id = @sched_id
      delete SOI 
      from sched_operation_item SOI, sched_item SI, sched_transfer ST where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.source_flag = 'P' and ST.sched_id = @sched_id
      delete STI 
      from sched_transfer_item STI, sched_item SI, sched_transfer ST where STI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.source_flag = 'P' and ST.sched_id = @sched_id
      delete SP
      from sched_purchase SP, sched_item SI, sched_transfer ST where SP.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.source_flag = 'P' and ST.sched_id = @sched_id
    end

    DELETE SI
    from sched_item SI, sched_transfer ST
    where SI.sched_transfer_id = ST.sched_transfer_id and ST.source_flag = 'P' and ST.sched_id = @sched_id

    return @@rowcount
  end
  if @mode = 'DL'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.location = @location
      delete SOI 
      from sched_operation_item SOI, sched_item SI  where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.location = @location
      delete STI 
      from sched_transfer_item STI, sched_item SI where STI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.location = @location
      delete SP
      from sched_purchase SP, sched_item SI where SP.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id and SI.location = @location
    end
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI, sched_transfer ST where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.sched_id = @sched_id and ST.location = @location
      delete SOI 
      from sched_operation_item SOI, sched_item SI, sched_transfer ST  where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.sched_id = @sched_id and ST.location = @location
      delete STI 
      from sched_transfer_item STI, sched_item SI, sched_transfer ST where STI.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.sched_id = @sched_id and ST.location = @location
      delete SP
      from sched_purchase SP, sched_item SI, sched_transfer ST where SP.sched_item_id = SI.sched_item_id
      and SI.sched_transfer_id = ST.sched_transfer_id and ST.sched_id = @sched_id and ST.location = @location
    end

    DELETE SI
    from sched_item SI
    where SI.sched_id = @sched_id and SI.location = @location

    DELETE SI
    from sched_item SI, sched_transfer ST
    where SI.sched_transfer_id = ST.sched_transfer_id and ST.sched_id = @sched_id and ST.location = @location

    return @@rowcount
  end
  if @mode = 'DM'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI 
      from sched_order_item SOI, sched_item SI where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id
      AND SI.location not in (SELECT L.location FROM locations_all L WHERE L.void != 'V')
      delete SOI 
      from sched_operation_item SOI, sched_item SI  where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id
      AND SI.location not in (SELECT L.location FROM locations_all L WHERE L.void != 'V')
      delete STI 
      from sched_transfer_item STI, sched_item SI where STI.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id 
      AND SI.location not in (SELECT L.location FROM locations_all L WHERE L.void != 'V')
      delete SP
      from sched_purchase SP, sched_item SI where SP.sched_item_id = SI.sched_item_id
      and SI.sched_id = @sched_id 
      AND SI.location not in (SELECT L.location FROM locations_all L WHERE L.void != 'V')
    end

    DELETE SI
    from sched_item SI
    where SI.sched_id = @sched_id 
      AND SI.location not in (SELECT L.location FROM locations_all L WHERE L.void != 'V')

    return @@rowcount
  end
end
GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_item] TO [public]
GO
