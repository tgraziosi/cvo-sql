SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_priority_insert_sp]
	@priority_code	varchar(5),
	@priority_desc	varchar(30),
	@status smallint = 0
AS

	IF EXISTS ( SELECT priority_code FROM cc_priority_codes WHERE priority_code = @priority_code )
		UPDATE	cc_priority_codes
		SET 		priority_desc = @priority_desc,
						status = @status
		WHERE 	priority_code = @priority_code
	ELSE
		INSERT cc_priority_codes VALUES (@priority_code, @priority_desc, @status)

GO
GRANT EXECUTE ON  [dbo].[cc_priority_insert_sp] TO [public]
GO
