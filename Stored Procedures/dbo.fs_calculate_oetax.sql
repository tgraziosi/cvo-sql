SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_calculate_oetax] @ord int, @ext int, 
 @err int out, @doctype int = 0, @trx_ctrl_num varchar(16) = '', @debug int = 0 AS

  declare @err_msg varchar(255)

  exec @err = fs_calculate_oetax_wrap @ord, @ext, @debug, 1, @doctype, @trx_ctrl_num, @err_msg OUT

  return @err

GO
GRANT EXECUTE ON  [dbo].[fs_calculate_oetax] TO [public]
GO
