SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_archklmt_sp_wrap] @customer_code varchar(10),  @date_entered	int,  @ordno int,  @ordext int   AS

BEGIN

DECLARE  @err1  int

exec  fs_archklmt_sp  @customer_code,  @date_entered,   @ordno,  @ordext,  @err1  OUT

Select @err1

END

GO
GRANT EXECUTE ON  [dbo].[fs_archklmt_sp_wrap] TO [public]
GO
