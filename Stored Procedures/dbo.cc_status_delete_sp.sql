SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_status_delete_sp]
	@status_code varchar(5)
AS
delete from cc_status_codes
	where status_code = @status_code
 
GO
GRANT EXECUTE ON  [dbo].[cc_status_delete_sp] TO [public]
GO
