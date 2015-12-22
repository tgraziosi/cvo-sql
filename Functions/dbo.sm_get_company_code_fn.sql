SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

	CREATE  FUNCTION [dbo].[sm_get_company_code_fn]  ( )
	RETURNS  varchar(8)
	BEGIN 
		DECLARE @company_code varchar(8)
		SELECT @company_code=company_code FROM glco
		RETURN @company_code
	END
		
 
GO
GRANT REFERENCES ON  [dbo].[sm_get_company_code_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_get_company_code_fn] TO [public]
GO
