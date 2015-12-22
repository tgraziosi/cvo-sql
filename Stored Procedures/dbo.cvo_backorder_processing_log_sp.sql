SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 04/06/13 - Writes to the Backorder Processing log

EXEC dbo.cvo_backorder_processing_log_sp	'Message'
*/
CREATE PROC [dbo].[cvo_backorder_processing_log_sp] @msg	VARCHAR(1000)

AS
BEGIN
	INSERT dbo.cvo_backorder_processing_log (
		log_time,
		log_msg)
	SELECT
		GETDATE(),
		@msg
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_log_sp] TO [public]
GO
