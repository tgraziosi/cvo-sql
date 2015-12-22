SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_post_ar] @user varchar(30),				-- mls 5/22/00 SCR 22851
                            @process_ctrl_num varchar(16) ,
                            @err int OUT   AS 
BEGIN

DECLARE @err1 int, @process_descr varchar(255)

select @process_descr = 'Online Post Shipments for batch: ' + @process_ctrl_num

exec dbo.adm_post_ar @err = @err1 OUT,
@post_description = @process_descr,
@user = @user,
@process_ctrl_num = @process_ctrl_num,
  @online_call = 0

select @err = @err1

END

GO
GRANT EXECUTE ON  [dbo].[fs_post_ar] TO [public]
GO
