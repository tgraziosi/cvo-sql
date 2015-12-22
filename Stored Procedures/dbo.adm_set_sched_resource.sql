SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_set_sched_resource]
@mode char(2),
@sched_id int = NULL,
@sched_resource_id int = NULL,
@location varchar(10) = NULL,
@resource_type_id int = NULL,
@resource_id int = NULL,
@source_flag char(1) = NULL,
@calendar_id int = NULL
as
begin
  if @mode = 'DL'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOR
      from sched_operation_resource SOR, sched_resource SR
      where SOR.sched_resource_id = SR.sched_resource_id
      and SR.sched_id = @sched_id and SR.location = @location
    end
    Delete sched_resource where sched_id = @sched_id and location = @location
    return @@rowcount 
  end
  if @mode = 'DM'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOR
      from sched_operation_resource SOR, sched_resource SR
      where SOR.sched_resource_id = SR.sched_resource_id 
      and SR.sched_id = @sched_id and SR.location not in
      (SELECT L.location FROM locations_all L WHERE L.void != 'V')
    end

    Delete sched_resource where sched_id = @sched_id and location not in
      (SELECT L.location FROM locations_all L WHERE L.void != 'V')
    return @@rowcount 
  end
  if @mode = 'DA'
  begin
    if (@@version like '%7.0%')
    begin
      delete SOR
      from sched_operation_resource SOR, sched_resource SR
      where SOR.sched_resource_id = SR.sched_resource_id
      and SR.sched_id = @sched_id
    end
    Delete sched_resource where sched_id = @sched_id 
    return @@rowcount 
  end
end
GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_resource] TO [public]
GO
