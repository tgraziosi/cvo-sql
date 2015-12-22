SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_priority_codes_sp]

AS
	SELECT priority_code, priority_desc
	FROM cc_priority_codes
	ORDER BY priority_code
 
GO
GRANT EXECUTE ON  [dbo].[cc_get_priority_codes_sp] TO [public]
GO
