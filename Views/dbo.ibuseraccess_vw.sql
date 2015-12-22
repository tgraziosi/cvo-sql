SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                



























CREATE VIEW [dbo].[ibuseraccess_vw]
AS
	SELECT DISTINCT	
		os.organization_id,
		u.user_id,
		u.user_name,
		manager = CASE u.manager WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		u.last_company_id,
		deleted = CASE u.deleted WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		designer = CASE u.designer WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
	FROM 
		smusers_vw u, smgrpdet_vw d, securitytokendetail o,
		sm_my_tokens myt, organizationsecurity os 
	WHERE	
		u.user_id = d.user_id
		AND d.group_id = o.group_id
		AND o.type= 4 
		AND myt.security_token = o.security_token
		AND myt.security_token = os.security_token
		AND ( dbo.sm_user_is_administrator_fn()=0
	   	OR  dbo.sm_ext_security_is_installed_fn() =1 )
	
	
	UNION
	
	SELECT DISTINCT 
		o.organization_id,
		u.user_id,
		u.user_name,
		manager = CASE u.manager WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		u.last_company_id,
		deleted = CASE u.deleted WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		designer = CASE u.designer WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
	FROM smusers_vw u, Organization o
	WHERE  dbo.sm_user_is_administrator_fn()=1
	
	UNION
	
	SELECT DISTINCT 
		o.organization_id,
		u.user_id,
		u.user_name,
		manager = CASE u.manager WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		u.last_company_id,
		deleted = CASE u.deleted WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		designer = CASE u.designer WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
	FROM smusers_vw u, Organization o
	WHERE  o.outline_num = '1'
		AND dbo.sm_ext_security_is_installed_fn() =0
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ibuseraccess_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibuseraccess_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibuseraccess_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibuseraccess_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibuseraccess_vw] TO [public]
GO
