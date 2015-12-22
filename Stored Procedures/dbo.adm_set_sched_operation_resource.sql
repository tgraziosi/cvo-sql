SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create procedure [dbo].[adm_set_sched_operation_resource]
@mode char(1),
@sched_operation_id int = 0,
@sched_resource_id int = 0,
@setup_datetime datetime = NULL,
@pool_qty float = NULL
as
begin
  if @mode = 'I'
  begin
    if not exists (select 1 from sched_operation_resource (nolock) 
      where sched_operation_id = @sched_operation_id and sched_resource_id = @sched_resource_id)
      Insert sched_operation_resource 
        (sched_operation_id,sched_resource_id,setup_datetime,pool_qty)
      values
        (@sched_operation_id,@sched_resource_id,@setup_datetime,@pool_qty)
    else
      update sched_operation_resource
      set setup_datetime = @setup_datetime,
        pool_qty = @pool_qty
      where sched_operation_id = @sched_operation_id and sched_resource_id = @sched_resource_id
  end
  if @mode = 'D'
  begin
    if @sched_operation_id > 0
    begin
      delete from sched_operation_resource
      where sched_operation_id = @sched_operation_id

      return @@rowcount
    end
    if @sched_resource_id > 0
    begin
      delete from sched_operation_resource
      where sched_resource_id = @sched_resource_id

      return @@rowcount
    end
  end
end

GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_operation_resource] TO [public]
GO
