SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2005 Epicor Software Corporation, 2005    
                  All Rights Reserved                    
*/                                                


CREATE  FUNCTION [dbo].[sm_get_orgs_with_access_fn]  ()
	RETURNS TABLE 
AS
	
RETURN   
	SELECT DISTINCT organization_id 
	FROM organizationsecurity o, securitytokendetail td, smgrpdet_vw d, smspiduser_vw v
		WHERE  o.security_token = td.security_token
		AND td.type =4
		AND td.group_id = d.group_id
		AND d.domain_username = v.user_name
		AND v.spid = @@SPID

	UNION
	SELECT DISTINCT organization_id FROM Organization_all
			WHERE ( dbo.sm_user_is_administrator_fn()=1 OR  dbo.sm_ext_security_is_installed_fn() =0 )
			
                  
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[sm_get_orgs_with_access_fn] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_get_orgs_with_access_fn] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_get_orgs_with_access_fn] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_get_orgs_with_access_fn] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_get_orgs_with_access_fn] TO [public]
GO
