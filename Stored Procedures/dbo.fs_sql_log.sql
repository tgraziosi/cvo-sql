SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sql_log] @msg varchar(255) AS

INSERT sql_log (log_date,log_msg) select getdate(), @msg

GO
GRANT EXECUTE ON  [dbo].[fs_sql_log] TO [public]
GO
