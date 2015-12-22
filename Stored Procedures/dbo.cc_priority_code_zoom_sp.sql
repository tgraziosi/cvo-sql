SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_priority_code_zoom_sp]
	@priority_code varchar(5),
	@direction tinyint = 0

AS
	SET rowcount 50
		IF @direction = 0
			SELECT priority_code "Code", priority_desc "Description"
			FROM cc_priority_codes
			WHERE priority_code >= @priority_code
			ORDER BY priority_code
		IF @direction = 1
			SELECT priority_code "Code", priority_desc "Description"
			FROM cc_priority_codes
			WHERE priority_code < @priority_code
			ORDER BY priority_code DESC
		IF @direction = 2
			SELECT priority_code "Code", priority_desc "Description"
			FROM cc_priority_codes
			WHERE priority_code > @priority_code
			ORDER BY priority_code
		
	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_priority_code_zoom_sp] TO [public]
GO
