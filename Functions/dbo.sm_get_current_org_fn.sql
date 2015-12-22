SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

	CREATE  FUNCTION [dbo].[sm_get_current_org_fn]  ( )
	RETURNS  varchar(30)
	BEGIN 
--		DECLARE @org_id varchar(30)
--		SELECT @org_id = org_id FROM smspiduser_vw spid WHERE spid.spid = @@SPID  
--		RETURN @org_id

		DECLARE @org_id varchar(30) 
		SELECT @org_id = organization_id from Organization_all where outline_num = '1'
		RETURN @org_id

	END
		
GO
GRANT REFERENCES ON  [dbo].[sm_get_current_org_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_get_current_org_fn] TO [public]
GO
