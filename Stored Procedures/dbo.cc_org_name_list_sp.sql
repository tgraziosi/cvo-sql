SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_org_name_list_sp] 	@db varchar(255) = ''

AS

	EXEC(	'	SELECT org_id, OrganizationName 
					FROM ' + @db + '..IB_Organization_vw
					ORDER BY OrganizationName ' )

		
GO
GRANT EXECUTE ON  [dbo].[cc_org_name_list_sp] TO [public]
GO
