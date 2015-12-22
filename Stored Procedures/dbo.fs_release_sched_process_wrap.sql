SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[fs_release_sched_process_wrap] @sched_process_id int, @prod_no int, @prod_ext int, @who varchar(20) as
BEGIN
declare @rc int, @err_txt varchar(80)
select @err_txt = ''

exec @rc = dbo.fs_release_sched_process @sched_process_id, @prod_no OUTPUT , @prod_ext OUTPUT , @who, 1

if @rc <> 1
begin
  select @err_txt = 
    case @rc 
      when 60110 then 'The user specified does not exist in Distribution Suite.'
      when 60240 then 'Unable to obtain production number from ERA'
      when 60241 then 'Unable to update production number in ERA'
      when 63143 then 'Can not release an item which is obsolete'
      when 66040 then 'Unable to enter production in ERA'
      when 69111 then 'The planned production does not exist'
      when 69130 then 'The scheduled production has already been released'
      when 69131 then 'The planned production did not have a single product defined'
      when 69132 then 'The planned item does not exist at the production location'
      when 69140 then 'Unable to update process as released'
      else 'Error ' + convert(varchar(10),@rc) + ' was returned from the operation.'
    end
end

SELECT 	@prod_no, @prod_ext, @rc, @err_txt
END 

GO
GRANT EXECUTE ON  [dbo].[fs_release_sched_process_wrap] TO [public]
GO
