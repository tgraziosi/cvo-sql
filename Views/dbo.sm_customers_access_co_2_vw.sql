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



























CREATE VIEW [dbo].[sm_customers_access_co_2_vw]
AS
		SELECT DISTINCT a.customer_code, os.organization_id 
		FROM armaster_all a, smcustomergrpdet d,securitytokendetail o,
		     sm_my_tokens	myt, organizationsecurity os 
	    	   	WHERE
		            a.customer_code like d.customer_mask

			   AND d.group_id = o.group_id
			   AND o.type= 3 
			   AND myt.security_token = o.security_token
			   AND myt.security_token = os.security_token
			   AND ( dbo.sm_user_is_administrator_fn()=0
			   OR  dbo.sm_ext_security_is_installed_fn() =1 )
	UNION 
		SELECT DISTINCT a.customer_code, o.organization_id
		FROM armaster_all a, smcustomergrpdet d, smcustomergrphdr h,
			Organization o
			WHERE
		            a.customer_code like d.customer_mask
 			   AND h.group_id = d.group_id
			   AND h.global_flag = 1
			 AND  ( dbo.sm_user_is_administrator_fn()=0
			OR dbo.sm_ext_security_is_installed_fn() =1 )

	UNION
		SELECT DISTINCT a.customer_code, o.organization_id
		FROM armaster_all a, Organization o
		WHERE  dbo.sm_user_is_administrator_fn()=1
	UNION
		SELECT DISTINCT a.customer_code, o.organization_id
		FROM armaster_all a, Organization o
		WHERE  o.outline_num = '1'
			AND dbo.sm_ext_security_is_installed_fn() =0


/**/                                              
GO
GRANT SELECT ON  [dbo].[sm_customers_access_co_2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_customers_access_co_2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_customers_access_co_2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_customers_access_co_2_vw] TO [public]
GO
