SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_account_vs_org_reg_sp]
AS
/* Drop */
DECLARE @buf varchar(8000)
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_account_vs_org_fn'' ) 
		DROP FUNCTION sm_account_vs_org_fn '
EXEC (@buf)
/* Creation */
SELECT @buf =	' CREATE FUNCTION sm_account_vs_org_fn (@account_code varchar(32), @org_id varchar(30))
				RETURNS smallint '
IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
		BEGIN
			SELECT @buf = @buf + '
				BEGIN		
						DECLARE @ret SMALLINT
						SELECT @ret = count (access)
						FROM (
				
						SELECT  1 access
						FROM smaccountgrpdet d,securitytokendetail o,
						     organizationsecurity	org, sm_my_tokens	myt
							WHERE
						           @account_code like d.account_mask
							   AND d.group_id = o.group_id
							   AND o.type=  1
							   AND org.security_token = o.security_token
							   AND myt.security_token = org.security_token
							   AND org.organization_id = @org_id
					    UNION 
						SELECT  1
						FROM smaccountgrpdet d,securitytokendetail o, smaccountgrphdr h
							WHERE
						            @account_code like d.account_mask
				 			   AND h.group_id = d.group_id
							   AND h.global_flag = 1
					UNION 
						SELECT  1 WHERE EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
							  OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME()  )
						) a
					RETURN @ret
				END '
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + '
				BEGIN	
					RETURN 1 
				END
				'			
		END
EXEC (@buf)
/* Perission */
SELECT @buf ='	GRANT EXECUTE , REFERENCES ON sm_account_vs_org_fn TO PUBLIC '
EXEC (@buf)
GO
GRANT EXECUTE ON  [dbo].[sm_account_vs_org_reg_sp] TO [public]
GO
