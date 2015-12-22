SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_logoff_reg_sp] 
AS
DECLARE @buf varchar(8000)
DECLARE	@buf2  varchar(100)
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_logoff_sp'' ) 
		DROP PROCEDURE sm_logoff_sp '
EXEC (@buf)

SELECT @buf =	'CREATE PROCEDURE sm_logoff_sp
		AS '

IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=0 )
	AND EXISTS (SELECT 1 FROM glco WHERE ib_flag = 0)
		BEGIN
			SELECT @buf = @buf + ' 
			RETURN 0
		'
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + '	
		IF (EXISTS (select 1 from CVO_Control..dminfo WHERE property_id = 53000) AND SUSER_SNAME() NOT IN (''pltsa'', ''sa''))
			RETURN 0


		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = ''smspiduser'' )     
		BEGIN

			DELETE smspiduser WHERE spid = @@SPID

			    DELETE smspiduser 
			    WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)

		    
		END

		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = ''smspiduser_vw'' )     
		BEGIN
		
			DELETE smspiduser_vw WHERE spid = @@SPID


			DELETE smspiduser_vw 
			    WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)	
			
		END '
		END
		
EXEC (@buf)

SELECT @buf ='	GRANT EXECUTE  ON sm_logoff_sp TO PUBLIC '
EXEC (@buf)
GO
GRANT EXECUTE ON  [dbo].[sm_logoff_reg_sp] TO [public]
GO
