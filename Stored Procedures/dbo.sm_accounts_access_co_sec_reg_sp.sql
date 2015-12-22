SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_accounts_access_co_sec_reg_sp] 
AS
DECLARE @buf varchar(8000)
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_accounts_access_co_sec_vw'' ) 
		DROP VIEW sm_accounts_access_co_sec_vw  '
EXEC (@buf)

SELECT @buf =	' CREATE VIEW sm_accounts_access_co_sec_vw AS'
	IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
			BEGIN
		
				SELECT @buf = @buf + ' 
							SELECT DISTINCT a.account_code 
							FROM glchart a, sm_account_masks_curr_org_vw t
					    	   	WHERE a.account_code like t.account_mask ' 
			END
		ELSE
			BEGIN
				SELECT @buf = @buf + ' SELECT DISTINCT a.account_code 
						       FROM glchart a '
			END
EXEC (@buf)

SELECT @buf ='	GRANT ALL ON sm_accounts_access_co_sec_vw TO PUBLIC '
EXEC (@buf)
GO
GRANT EXECUTE ON  [dbo].[sm_accounts_access_co_sec_reg_sp] TO [public]
GO
