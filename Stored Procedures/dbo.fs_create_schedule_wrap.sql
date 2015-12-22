SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[fs_create_schedule_wrap] @sched_id int , @sched_name varchar(16) as
BEGIN
declare @rc int, @err_txt varchar(80)
select @err_txt = ''

exec @rc = dbo.fs_create_schedule @sched_id OUTPUT , @sched_name OUTPUT, 1

if @rc <> 1
begin
  select @err_txt = 
    case @rc  
	when 69040 then 'Problem creating new schedule encountered.'
      else 'Error ' + convert(varchar(10),@rc) + ' was returned from the operation.'
    end
end

SELECT 	@sched_id, @rc, @err_txt
END 

GO
GRANT EXECUTE ON  [dbo].[fs_create_schedule_wrap] TO [public]
GO
