SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROC	[dbo].[cc_pfinv_drop_table_sp] @table_name varchar(255)

AS

	EXEC ( ' IF EXISTS (SELECT * FROM sysobjects WHERE name = "' + @table_name + '" ) 
					DROP TABLE ' + @table_name )

GO
GRANT EXECUTE ON  [dbo].[cc_pfinv_drop_table_sp] TO [public]
GO
