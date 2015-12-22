SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[sm_vendors_access]
AS
		SELECT DISTINCT a.vendor_code 
		FROM apmaster_all a, smvendorgrpdet d,securitytokendetail o,
		     sm_my_tokens	myt
	    	   	WHERE
		              a.vendor_code like d.vendor_mask
			   AND d.group_id = o.group_id
			   AND o.type= 2 
			   AND myt.security_token = o.security_token
			   AND ( dbo.sm_user_is_administrator_fn()=0
			   OR  dbo.sm_ext_security_is_installed_fn() =1 )
	UNION 
		SELECT DISTINCT a.vendor_code 
		FROM apmaster_all a, smvendorgrpdet d, smvendorgrphdr h
			WHERE
		            a.vendor_code like d.vendor_mask			
 			   AND h.group_id = d.group_id
			   AND h.global_flag = 1
			 AND  ( dbo.sm_user_is_administrator_fn()=0
			OR dbo.sm_ext_security_is_installed_fn() =1 )
	UNION
		SELECT DISTINCT a.vendor_code FROM apmaster_all a
		WHERE  dbo.sm_user_is_administrator_fn()=1
		  OR dbo.sm_ext_security_is_installed_fn() =0 

GO
GRANT SELECT ON  [dbo].[sm_vendors_access] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_vendors_access] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_vendors_access] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_vendors_access] TO [public]
GO
