SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_dump_tran]  AS
BEGIN

   declare @dbname varchar(30)
   select @dbname = db_name()
   backup Log @dbname with no_log
END

GO
GRANT EXECUTE ON  [dbo].[fs_dump_tran] TO [public]
GO
