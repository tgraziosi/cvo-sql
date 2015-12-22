SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[fs_duplicate_schedule_wrap] @sched_id int , @sched_name varchar(16) as
BEGIN
declare @rc int, @err_txt varchar(80)
select @err_txt = ''

exec @rc = dbo.fs_duplicate_schedule @sched_id OUTPUT , @sched_name, 1

if @rc <> 1
begin
  select @err_txt = 
    case @rc 
	when 69011 then 'A schedule scenario already exists with that name.'
	when 69041 then 'Problem creating new schedule encountered.'
	when 69042 then 'Problem creating new schedule encountered.'
      else 'Error ' + convert(varchar(10),@rc) + ' was returned from the operation.'
    end
end

SELECT 	@sched_id, @rc, @err_txt
END 

GO
GRANT EXECUTE ON  [dbo].[fs_duplicate_schedule_wrap] TO [public]
GO
