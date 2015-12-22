SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_get_control_db_list_sp]	
AS

	SELECT master_db_name from master..masterlst

GO
GRANT EXECUTE ON  [dbo].[cc_get_control_db_list_sp] TO [public]
GO
