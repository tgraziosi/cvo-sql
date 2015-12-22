SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_status_insert_sp]	@status_code varchar(5),
																			@status_desc varchar(30),
																			@status smallint = 0
	AS

	IF EXISTS ( SELECT status_code FROM cc_status_codes WHERE status_code = @status_code )
		UPDATE	cc_status_codes
		SET 		status_desc = @status_desc,
						status = @status
		WHERE 	status_code = @status_code
	ELSE
		INSERT cc_status_codes 
		VALUES (@status_code, @status_desc, @status)
GO
GRANT EXECUTE ON  [dbo].[cc_status_insert_sp] TO [public]
GO
