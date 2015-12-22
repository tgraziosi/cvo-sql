SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE FUNCTION [dbo].[sm_account_vs_org_fn] (@account_code varchar(32), @org_id varchar(30))
RETURNS smallint
BEGIN		
		DECLARE @ret SMALLINT
		SELECT @ret = count (access)
		FROM (

		SELECT DISTINCT 1 access
		FROM smaccountgrpdet d,securitytokendetail o,
		     organizationsecurity	org, sm_my_tokens	myt
			WHERE
		           @account_code like d.account_mask
			   AND d.group_id = o.group_id
			   AND o.type=  1
			   AND org.security_token = o.security_token
			   AND myt.security_token = org.security_token
			   AND org.organization_id = @org_id
			   AND (dbo.sm_ext_security_is_installed_fn() =1 OR  dbo.sm_user_is_administrator_fn()=0)
	    UNION 
		SELECT DISTINCT 1
		FROM smaccountgrpdet d,securitytokendetail o, smaccountgrphdr h
			WHERE
		            @account_code like d.account_mask
 			   AND h.group_id = d.group_id
			   AND h.global_flag = 1
			 AND   (dbo.sm_ext_security_is_installed_fn() =1 OR  dbo.sm_user_is_administrator_fn()=0)
	UNION SELECT 1 WHERE (dbo.sm_ext_security_is_installed_fn() =0 OR  dbo.sm_user_is_administrator_fn()=1)
		) a
	RETURN @ret
END
GO
GRANT REFERENCES ON  [dbo].[sm_account_vs_org_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_account_vs_org_fn] TO [public]
GO
