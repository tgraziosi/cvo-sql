SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_post_cm_wrap]  @process_ctrl_num varchar(16) 
AS 
BEGIN

DECLARE @err1 int

exec fs_post_cm  @process_ctrl_num, @err1 OUT

Select @err1 

END

GO
GRANT EXECUTE ON  [dbo].[fs_post_cm_wrap] TO [public]
GO
