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



























CREATE  VIEW [dbo].[sm_user_tokens_vw]
AS
	SELECT DISTINCT security_token, u.user_name, h.global_flag 
	FROM securitytokendetail t ,smgrpdet_vw u, smgrps_vw h
	WHERE  
		t.group_id = u.group_id
		AND t.group_id = h.group_id
		AND t.type 	= 4
		AND h.type 	= 4
/**/                                              
GO
GRANT SELECT ON  [dbo].[sm_user_tokens_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_user_tokens_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_user_tokens_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_user_tokens_vw] TO [public]
GO
