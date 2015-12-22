SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_status_codes_sp]

AS
select status_code, status_desc
	from cc_status_codes
	order by status_code
 
GO
GRANT EXECUTE ON  [dbo].[cc_get_status_codes_sp] TO [public]
GO
