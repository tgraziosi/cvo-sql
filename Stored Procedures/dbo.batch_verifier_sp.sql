SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[batch_verifier_sp]
	    @batch_ctrl_num varchar(16),
	    @db_name	    varchar(128),
	    @table_name     varchar(31)
AS
 EXEC ('	IF ((SELECT COUNT(1) FROM ' + @db_name+'..'+@table_name+ ' WHERE batch_code = '''+@batch_ctrl_num+''')  =
 		(SELECT COUNT(1) FROM ' + @db_name+'..'+@table_name+ '_all WHERE batch_code ='''+@batch_ctrl_num+''' ) )
			SELECT 1
		ELSE 
			SELECT 0 ')

GO
GRANT EXECUTE ON  [dbo].[batch_verifier_sp] TO [public]
GO
