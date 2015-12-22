SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[sm_ext_security_is_installed_fn] ( ) 
	RETURNS smallint
BEGIN
	  DECLARE @sec_flag SMALLINT
	  
	  SELECT @sec_flag =ISNULL(extended_security_flag ,0)
	   		FROM smcomp_vw		
	  RETURN @sec_flag
END
GO
GRANT REFERENCES ON  [dbo].[sm_ext_security_is_installed_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_ext_security_is_installed_fn] TO [public]
GO
