SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_set_sched_model]
@mode char(2),
@sched_id int = NULL
as
begin
  if @mode = 'D'
  begin
    exec adm_set_sched_process 'DA',NULL,@sched_id
    exec adm_set_sched_location 'DA',@sched_id

    delete sched_model
    where sched_id = @sched_id
  end
end


GO
GRANT EXECUTE ON  [dbo].[adm_set_sched_model] TO [public]
GO
