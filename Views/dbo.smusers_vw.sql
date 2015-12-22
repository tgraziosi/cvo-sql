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

CREATE VIEW [dbo].[smusers_vw]
AS
	select	user_id,
		user_name,
                manager,
		last_company_id,
		deleted,
		designer,
 		external_user_flag,
		domain_username,
		nt_authentication_flag
	from CVO_Control..smusers

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[smusers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smusers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smusers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smusers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smusers_vw] TO [public]
GO
