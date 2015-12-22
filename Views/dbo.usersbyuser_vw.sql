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



























CREATE VIEW [dbo].[usersbyuser_vw]
AS
SELECT DISTINCT	
	u.user_id,
	u.user_name,
	manager = CASE u.manager WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
	u.last_company_id,
	deleted = CASE u.deleted WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
	designer = CASE u.designer WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
FROM 
	smusers_vw u, smgrpdet_vw d, securitytokendetail o,
	sm_my_tokens myt
WHERE	
	u.user_id = d.user_id
	AND d.group_id = o.group_id
	AND o.type= 4 
	AND myt.security_token = o.security_token
	AND ( dbo.sm_user_is_administrator_fn()=0
   	OR  dbo.sm_ext_security_is_installed_fn() =1 )

UNION

SELECT DISTINCT
	u.user_id,
	u.user_name,
	manager = CASE u.manager WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
	u.last_company_id,
	deleted = CASE u.deleted WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
	designer = CASE u.designer WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
FROM
	smusers_vw u
WHERE
	dbo.sm_user_is_administrator_fn()=1
   	OR  dbo.sm_ext_security_is_installed_fn() =0
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[usersbyuser_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[usersbyuser_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[usersbyuser_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[usersbyuser_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[usersbyuser_vw] TO [public]
GO
