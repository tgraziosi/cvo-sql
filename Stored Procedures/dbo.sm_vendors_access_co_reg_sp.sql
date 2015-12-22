SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_vendors_access_co_reg_sp] 
AS
DECLARE @buf varchar(8000)
IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = 'sm_vendors_access_co_vw' ) 
		DROP VIEW sm_vendors_access_co_vw
EXEC (@buf)

SELECT @buf =	' CREATE VIEW sm_vendors_access_co_vw AS'
IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
		BEGIN
			SELECT @buf = @buf + '
					SELECT DISTINCT a.vendor_code 
					FROM apmaster_all a, smvendorgrpdet d,securitytokendetail o,
					     sm_my_tokens	myt, organizationsecurity os 
				    	   	WHERE
					            a.vendor_code like d.vendor_mask
						   AND d.group_id = o.group_id
						   AND o.type= 2 
						   AND myt.security_token = o.security_token
						   AND myt.security_token = os.security_token
						   AND os.organization_id = ( SELECT org_id 
											FROM smspiduser_vw spid
										        WHERE spid.spid = @@SPID )					
					UNION 
					SELECT DISTINCT a.vendor_code 
					FROM apmaster_all a, smvendorgrpdet d, smvendorgrphdr h
						WHERE
					            a.vendor_code like d.vendor_mask
			 			   AND h.group_id = d.group_id
						   AND h.global_flag = 1
					UNION
					SELECT DISTINCT a.vendor_code FROM apmaster_all a
					WHERE  EXISTS (SELECT 1 FROM smspiduser_vw WHERE spid = @@SPID AND global_user = 1 )
								    	       OR EXISTS ( SELECT 1 FROM smisadmin_vw WHERE domain_username = SUSER_SNAME() ) '	
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + ' 
						SELECT DISTINCT a.customer_code 
							FROM armaster_all a '
		END

	
EXEC (@buf)

SELECT @buf = ' GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON sm_vendors_access_co_vw TO PUBLIC               '
EXEC (@buf)    

GO
GRANT EXECUTE ON  [dbo].[sm_vendors_access_co_reg_sp] TO [public]
GO
