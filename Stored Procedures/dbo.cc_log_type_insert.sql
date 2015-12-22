SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_log_type_insert]
	@log_desc varchar(50),
	@short_desc varchar(8),
	@status smallint = 0

AS
	DECLARE @logType int

	IF (SELECT max(log_type) FROM cc_log_types) IS NOT NULL 
		SELECT @logType = (SELECT MAX(log_type) FROM cc_log_types) + 1 
	ELSE 
		SELECT @logType = 1 


	IF EXISTS ( SELECT short_desc FROM cc_log_types WHERE short_desc = @short_desc )
		UPDATE	cc_log_types
		SET 		description = @log_desc,
						status = @status
		WHERE 	short_desc = @short_desc
	ELSE
	
		INSERT cc_log_types VALUES(@logType, @log_desc ,@short_desc, @status)


GO
GRANT EXECUTE ON  [dbo].[cc_log_type_insert] TO [public]
GO
