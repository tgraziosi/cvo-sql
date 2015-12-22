SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_order]
@mode char(2),
@sched_id int = NULL,
@sched_order_id int = 0,
@location varchar(10) = NULL,
@done_datetime datetime = NULL,
@part_no varchar(30) = NULL,
@uom_qty float = NULL,
@uom char(2) = NULL,
@order_priority_id int = NULL,
@source_flag char(1) = NULL,
@order_no int = NULL,
@order_ext int = NULL,
@order_line int = NULL,
@order_line_kit int = NULL,
@prod_no int = NULL,
@prod_ext int = NULL,
@action_datetime datetime = NULL,
@action_flag char(1) = '?'
as
begin
declare @identity int

  if @mode = 'I'
  begin
    Insert sched_order
      (sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,order_no,order_ext,order_line,order_line_kit,prod_no,prod_ext,action_datetime,action_flag)
    values
      (@sched_id,@location,@done_datetime,@part_no,@uom_qty,@uom,@order_priority_id,@source_flag,@order_no,@order_ext,@order_line,@order_line_kit,@prod_no,@prod_ext,@action_datetime,@action_flag)

    select @identity = @@identity
 
    return @identity
  end
  if @mode = 'U1'
  begin
    update sched_order
    set action_datetime = @action_datetime,
      action_flag = @action_flag
    where sched_order_id = @sched_order_id

    return @@rowcount
  end
  if @mode = 'D'
  begin
    if (@@version like '%7.0%')
    begin
      delete sched_order_item where sched_order_id = @sched_order_id
    end
    Delete sched_order where sched_order_id = @sched_order_id
    return @@rowcount 
  end
  if @mode = 'DT'
  begin
    if exists (select 1 from sched_order where sched_order_id = @sched_order_id and source_flag = 'T')
    begin
    if (@@version like '%7.0%')
    begin
      delete sched_order_item where sched_order_id = @sched_order_id
    end
      Delete sched_order where sched_order_id = @sched_order_id
      return @@rowcount 
    end

    return 0
  end
  if @mode = 'DA'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI
      from sched_order SO, sched_order_item SOI where SOI.sched_order_id = SO.sched_order_id
      and SO.sched_id = @sched_id
    end
    Delete sched_order where sched_id = @sched_id
    return @@rowcount 
  end
  if @mode = 'DC'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI
      from sched_order SO, sched_order_item SOI where SOI.sched_order_id = SO.sched_order_id
      and SO.sched_id = @sched_id AND source_flag between 'A' and 'N' 
      and source_flag in ('A','M','N')
    end
    DELETE	sched_order
    WHERE	sched_id = @sched_id AND source_flag between 'A' and 'N' 
      and source_flag in ('A','M','N')
    return @@rowcount 
  end
  if @mode = 'DL'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI
      from sched_order SO, sched_order_item SOI where SOI.sched_order_id = SO.sched_order_id
      and SO.sched_id = @sched_id AND SO.location = @location
    end

    DELETE	sched_order
    WHERE	sched_id = @sched_id AND location = @location
    return @@rowcount 
  end
  if @mode = 'DM'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOI
      from sched_order SO, sched_order_item SOI
      where SOI.sched_order_id = SO.sched_order_id
      and SO.sched_id = @sched_id 
      AND NOT EXISTS(SELECT 1 FROM locations_all L WHERE L.location = SO.location AND L.void != 'V')
    end

    DELETE	SO
    from sched_order SO
    where SO.sched_id = @sched_id 
      AND NOT EXISTS(SELECT 1 FROM locations_all L WHERE L.location = SO.location AND L.void != 'V')
    return @@rowcount 
  end

end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_order] TO [public]
GO
