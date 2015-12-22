SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                


















CREATE VIEW [dbo].[smccausers_vw] AS

	SELECT u.timestamp, u.user_id, u.user_name, u.manager, u.last_company_id, u.deleted, u.designer, u.domain_username domain_name 
		FROM CVO_Control..smusers  u 
	WHERE IS_SRVROLEMEMBER ( 'sysadmin', u.domain_username ) = 1
		AND dbo.sm_other_user_is_administrator_fn ( u.domain_username ) = 1
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[smccausers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smccausers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smccausers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smccausers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smccausers_vw] TO [public]
GO
