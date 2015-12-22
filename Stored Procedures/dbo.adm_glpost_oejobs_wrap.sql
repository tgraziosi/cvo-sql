SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_glpost_oejobs_wrap] @process_ctrl_num varchar(32),@user varchar(32) AS

BEGIN

DECLARE @err int

EXEC adm_glpost_oejobs @process_ctrl_num, @user, @err OUT

SELECT @err 'err'

END

GO
GRANT EXECUTE ON  [dbo].[adm_glpost_oejobs_wrap] TO [public]
GO
