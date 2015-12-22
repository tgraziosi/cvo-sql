SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  VIEW [dbo].[sm_my_tokens]
AS
		SELECT DISTINCT security_token 
		FROM securitytokendetail t ,smgrpdet_vw u,smspiduser_vw spid
			WHERE  
				 t.group_id = u.group_id
				AND t.type 	= 4
				AND spid.user_name =  u.domain_username
				AND spid.spid = @@spid

GO
GRANT SELECT ON  [dbo].[sm_my_tokens] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_my_tokens] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_my_tokens] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_my_tokens] TO [public]
GO
