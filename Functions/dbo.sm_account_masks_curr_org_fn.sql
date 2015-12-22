SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[sm_account_masks_curr_org_fn]()
RETURNS @sec_account_mask TABLE ( account_mask varchar(32) )
AS
BEGIN
	IF EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
	OR EXISTS(SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME())
		INSERT INTO @sec_account_mask VALUES ('%')

	ELSE
	BEGIN
		INSERT INTO @sec_account_mask 
		SELECT DISTINCT d.account_mask 
		FROM smaccountgrpdet d,securitytokendetail o,
			sm_my_tokens	myt, organizationsecurity os 
		WHERE	d.group_id = o.group_id
		AND o.type= 1 
		AND myt.security_token = o.security_token
		AND myt.security_token = os.security_token
		AND (os.organization_id = ( SELECT org_id 
					FROM smspiduser_vw spid
				        WHERE spid.spid = @@SPID )
		OR
			( SELECT db_name 
					FROM smspiduser_vw spid
				        WHERE spid.spid = @@SPID ) <> db_name()
		)
		UNION		
		SELECT d.account_mask
		FROM smaccountgrpdet d, smaccountgrphdr h
		WHERE h.group_id = d.group_id
		AND h.global_flag = 1		
	END
	RETURN
END
GO
GRANT REFERENCES ON  [dbo].[sm_account_masks_curr_org_fn] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_account_masks_curr_org_fn] TO [public]
GO
