SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_vendor_vs_org_reg_sp]
AS
DECLARE @buf varchar(8000)
SELECT @buf =	' IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_vendor_vs_org_fn'' ) 
		DROP FUNCTION sm_vendor_vs_org_fn '
EXEC (@buf)

SELECT @buf =	' CREATE FUNCTION sm_vendor_vs_org_fn (@vendor_code varchar(12), @org_id varchar(30))
			RETURNS smallint '
IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
		BEGIN
			SELECT @buf = @buf + '
			BEGIN		
					DECLARE @ret SMALLINT
					SELECT @ret = count (access)
					FROM (
			
					SELECT DISTINCT 1 access
					FROM smvendorgrpdet d,securitytokendetail o,
					     organizationsecurity	org, sm_my_tokens	myt
						WHERE
					           @vendor_code like d.vendor_mask
						   AND d.group_id = o.group_id
						   AND o.type=  2
						   AND org.security_token = o.security_token
						   AND myt.security_token = org.security_token
						   AND org.organization_id = @org_id
				    UNION 
					SELECT DISTINCT 1
					FROM smvendorgrpdet d,securitytokendetail o, smvendorgrphdr h
						WHERE
					           @vendor_code like d.vendor_mask
			 			   AND h.group_id = d.group_id
						   AND h.global_flag = 1
				   UNION 
					SELECT DISTINCT 1 
					WHERE EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
							  OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME()  )
					) a
				RETURN @ret 
			END '
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + '	BEGIN	
							RETURN 1 
						END '
		END
EXEC (@buf)

SELECT @buf = ' GRANT EXECUTE , REFERENCES ON sm_vendor_vs_org_fn TO PUBLIC'
EXEC (@buf)     
GO
GRANT EXECUTE ON  [dbo].[sm_vendor_vs_org_reg_sp] TO [public]
GO
