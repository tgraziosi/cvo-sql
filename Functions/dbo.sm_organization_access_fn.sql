SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE FUNCTION [dbo].[sm_organization_access_fn] ( @org_id varchar(30)) 
			 RETURNS smallint 
			BEGIN   
			     RETURN 1 
			END
GO
GRANT EXECUTE ON  [dbo].[sm_organization_access_fn] TO [public]
GO
