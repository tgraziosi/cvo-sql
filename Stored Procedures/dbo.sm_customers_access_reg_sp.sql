SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_customers_access_reg_sp] 
AS
DECLARE @buf varchar(8000)
SELECT @buf =	' IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_customers_access_vw'' ) 
		DROP VIEW sm_customers_access_vw'

EXEC (@buf)
SELECT @buf =	' CREATE VIEW sm_customers_access_vw AS'
IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
			BEGIN
				SELECT @buf = @buf + ' SELECT DISTINCT a.customer_code 
							FROM armaster_all a, smcustomergrpdet d,securitytokendetail o,
							     sm_my_tokens	myt
						    	   	WHERE
							            a.customer_code like d.customer_mask
								   AND d.group_id = o.group_id
								   AND o.type= 3 
								   AND myt.security_token = o.security_token
							UNION 
								SELECT DISTINCT a.customer_code 
								FROM armaster_all a, smcustomergrpdet d, smcustomergrphdr h
									WHERE
								            a.customer_code like d.customer_mask
						 			   AND h.group_id = d.group_id
									   AND h.global_flag = 1
							UNION
								SELECT DISTINCT a.customer_code 
								FROM armaster_all a
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
GO
GRANT EXECUTE ON  [dbo].[sm_customers_access_reg_sp] TO [public]
GO
