SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[sm_access_to_epmchdtl_fn] (@match_ctrl_num varchar(16))
RETURNS smallint
BEGIN		
		DECLARE @ret SMALLINT



		SELECT @ret = CASE WHEN COUNT (access) = 0 THEN 1 ELSE 0 END
		FROM (
		SELECT  dbo.sm_organization_access_fn(dbo.IBOrgbyAcct_fn(account_code))  access
		FROM epmchdtl d
			WHERE
				match_ctrl_num = @match_ctrl_num
		GROUP BY account_code

		) a
		WHERE a.access =0
		
	RETURN @ret
END
GO
GRANT REFERENCES ON  [dbo].[sm_access_to_epmchdtl_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_access_to_epmchdtl_fn] TO [public]
GO
