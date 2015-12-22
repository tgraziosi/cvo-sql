SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_check_company_db_list_sp]	@company_db varchar(255)
AS
SET QUOTED_IDENTIFIER OFF


	EXEC ('	IF EXISTS (SELECT name FROM ' + @company_db + '..sysobjects WHERE name = "' + 'cc_get_company_db_list_sp' + '" AND type = "' + 'P' + '" )
					SELECT 0
				ELSE
					SELECT 1 ' )

GO
GRANT EXECUTE ON  [dbo].[cc_check_company_db_list_sp] TO [public]
GO
