SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_get_current_org_reg_sp] 
AS
DECLARE @buf varchar(8000)

SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_get_current_org_fn'' ) 
		DROP FUNCTION sm_get_current_org_fn'
EXEC (@buf)

SELECT @buf =	' CREATE FUNCTION sm_get_current_org_fn ()
		  RETURNS varchar(30) 
		  BEGIN 
		  	DECLARE @org_id varchar(30) '

IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=0 )
	AND EXISTS (SELECT 1 FROM glco WHERE ib_flag = 0)
		BEGIN
			SELECT @buf = @buf + ' 
			SELECT @org_id = organization_id from Organization_all (nolock) where outline_num = ''1'' 
			RETURN @org_id
		END '
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + '	
			SELECT @org_id = org_id FROM smspiduser_vw spid (nolock)
			WHERE spid.spid = @@SPID   
			RETURN @org_id
		END '
		END
EXEC (@buf)

SELECT @buf ='	GRANT EXECUTE , REFERENCES ON sm_get_current_org_fn TO PUBLIC '
EXEC (@buf)
GO
GRANT EXECUTE ON  [dbo].[sm_get_current_org_reg_sp] TO [public]
GO
