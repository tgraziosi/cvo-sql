SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_status_code_sp]
	@status_code varchar(5),
	@direction tinyint = 0

AS
	SET rowcount 50
		IF @direction = 0
			SELECT status_code "Code", status_desc "Description"
			FROM cc_status_codes
			WHERE status_code >= @status_code
			ORDER BY status_code
		IF @direction = 1
			SELECT status_code "Code", status_desc "Description"
			FROM cc_status_codes
			WHERE status_code < @status_code
			ORDER BY status_code DESC
		IF @direction = 2
			SELECT status_code "Code", status_desc "Description"
			FROM cc_status_codes
			WHERE status_code > @status_code
			ORDER BY status_code
		
	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_status_code_sp] TO [public]
GO
