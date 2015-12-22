SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_close_batch]
			@process_ctrl_num	varchar(16),
			@online_call int = 1
AS
   declare @result int,
	   @process_state smallint

   select @result = 1
   select @process_state = 3

   exec @result = pctrlupd_sp	@process_ctrl_num,
				@process_state


if @online_call = 1
  select @result 'err_code'
else
  return @result
GO
GRANT EXECUTE ON  [dbo].[fs_close_batch] TO [public]
GO
