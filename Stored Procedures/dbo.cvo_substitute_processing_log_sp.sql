SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 04/06/13 - Writes to the Substitute Processing log

EXEC dbo.cvo_substitute_processing_log_sp	'Message'
*/
CREATE PROC [dbo].[cvo_substitute_processing_log_sp] @msg	VARCHAR(1000),
												 @debug SMALLINT = 1 -- 0 = Don't write, 1 = Write

AS
BEGIN
	IF @debug = 1
	BEGIN
		INSERT dbo.cvo_substitute_processing_log (
			spid,
			userid,
			log_time,
			log_msg)
		SELECT
			@@SPID,
			SUSER_SNAME(),
			GETDATE(),
			@msg
		END
END

GO
GRANT EXECUTE ON  [dbo].[cvo_substitute_processing_log_sp] TO [public]
GO
