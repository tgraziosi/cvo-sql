SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[sm_account_masks_by_org_vw] 
AS
SELECT '%' account_mask, organization_id, 0 global_flag FROM smspiduser_vw, Organization WHERE spid = @@SPID AND global_user = 1 
UNION
SELECT '%' account_mask, organization_id, 0 global_flag FROM  smisadmin_vw, Organization  WHERE domain_username = SUSER_SNAME()
UNION
SELECT DISTINCT d.account_mask , os.organization_id, 0
	FROM smaccountgrpdet d,securitytokendetail o,
		sm_my_tokens	myt, organizationsecurity os , Organization orgs
	WHERE	d.group_id = o.group_id
	AND o.type= 1 
	AND myt.security_token = o.security_token
	AND myt.security_token = os.security_token
	AND (os.organization_id = orgs.organization_id
	)
UNION		
SELECT d.account_mask, '', 1
	FROM smaccountgrpdet d, smaccountgrphdr h
	WHERE h.group_id = d.group_id
	AND h.global_flag = 1		

GO
GRANT REFERENCES ON  [dbo].[sm_account_masks_by_org_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_account_masks_by_org_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_account_masks_by_org_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_account_masks_by_org_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_account_masks_by_org_vw] TO [public]
GO
