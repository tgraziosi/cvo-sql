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



























CREATE VIEW [dbo].[sm_vendors_access_2_vw]
AS
		SELECT DISTINCT a.vendor_code, ut.user_name
		FROM apmaster_all a, smvendorgrpdet d,securitytokendetail o,
		     sm_user_tokens_vw	ut
	    	   	WHERE
		           a.vendor_code like d.vendor_mask
			   AND d.group_id = o.group_id
			   AND o.type= 2 
			   AND ut.security_token = o.security_token
			   AND dbo.sm_ext_security_is_installed_fn() =1 
	UNION 
		SELECT DISTINCT a.vendor_code, ut.user_name
		FROM apmaster_all a, smvendorgrpdet d, smvendorgrphdr h,
		     sm_user_tokens_vw ut
		WHERE
		           a.vendor_code like d.vendor_mask			
 			   AND h.group_id = d.group_id
			   AND h.global_flag = 1
			   AND  dbo.sm_ext_security_is_installed_fn() =1 
	UNION
		SELECT DISTINCT a.vendor_code, ut.user_name
		FROM apmaster_all a, sm_user_tokens_vw ut
		WHERE  dbo.sm_ext_security_is_installed_fn() =0
			OR ut.global_flag = 1


/**/                                              
GO
GRANT SELECT ON  [dbo].[sm_vendors_access_2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_vendors_access_2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_vendors_access_2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_vendors_access_2_vw] TO [public]
GO
