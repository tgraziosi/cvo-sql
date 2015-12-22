SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[adm_icv_post_cradj]  @user varchar(30), @process_ctrl_num varchar(16),
  @error_msg varchar(80) OUT as
begin
declare @err int

select @error_msg = ''
-- Is CCA installed?
if not exists (select 1 from config (nolock) where upper(flag) = 'CCA' 
  and upper(value_str) like 'Y%')
begin
  select @error_msg = 'CCA not installed'
  return 1
end

-- Is it set up to verify credit returns?
if not exists (select 1 from config (nolock) where upper(flag) = 'ICV_CREDIT' 
  and upper(value_str) = 'YES')
begin
  select @error_msg = 'CCA not set up to check credit returns'
  return 2
end

EXEC icv_fs_post_cradj @user, @process_ctrl_num, @err OUT

if @err <> 1 
begin
  select @error_msg = case @err
    when 10 then 'Could not find invoice for original order.'
    when 20 then 'Could not find credit memo.'
    when 30 then 'Could not find credit return without an adjustment.'
    when 40 then 'Found more than one credit return for invoice.'
    when 50 then 'Amount of credit return exceeds original payment.'
    when 60 then 'Could not obtain next credit adjustment number.'
    else 'Unknown error returned from icv_fs_post_cradj' 
    end

  if @err > 1
    select @err = @err * -1
end

return @err

end
GO
GRANT EXECUTE ON  [dbo].[adm_icv_post_cradj] TO [public]
GO
