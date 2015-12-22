SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[sm_access_to_glreadet_fn] (@journal_ctrl_num varchar(16))
RETURNS smallint
BEGIN		
		DECLARE @ret SMALLINT



		SELECT @ret = CASE WHEN COUNT (access) = 0 THEN 1 ELSE 0 END
		FROM (
		SELECT  dbo.sm_organization_access_fn(org_id)  access
		FROM glreadet 
		WHERE  	journal_ctrl_num = @journal_ctrl_num
			AND rec_company_code =  dbo.sm_get_company_code_fn()
		GROUP BY org_id 

		) a
		WHERE a.access =0
		
		RETURN @ret
END
GO
GRANT REFERENCES ON  [dbo].[sm_access_to_glreadet_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_access_to_glreadet_fn] TO [public]
GO
