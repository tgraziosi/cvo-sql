SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_priority_params_sp]

AS
	SELECT MIN(priority_code), MAX(priority_code)
	FROM cc_priority_codes
 
GO
GRANT EXECUTE ON  [dbo].[cc_get_priority_params_sp] TO [public]
GO
