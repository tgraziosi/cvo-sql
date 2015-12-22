SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/  

CREATE VIEW [dbo].[sm_account_masks_all_org_vw] as 
	SELECT '%' account_mask FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1
	UNION
	SELECT '%' account_mask FROM smisadmin_vw WHERE domain_username = SUSER_SNAME()
	UNION
	SELECT DISTINCT d.account_mask 
	FROM smaccountgrpdet d,securitytokendetail o,
		sm_my_tokens	myt
	WHERE	d.group_id = o.group_id
	AND o.type= 1 
	AND myt.security_token = o.security_token
	UNION		
	SELECT d.account_mask
	FROM smaccountgrpdet d, smaccountgrphdr h
	WHERE h.group_id = d.group_id
	AND h.global_flag = 1		

GO
GRANT REFERENCES ON  [dbo].[sm_account_masks_all_org_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_account_masks_all_org_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_account_masks_all_org_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_account_masks_all_org_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_account_masks_all_org_vw] TO [public]
GO
