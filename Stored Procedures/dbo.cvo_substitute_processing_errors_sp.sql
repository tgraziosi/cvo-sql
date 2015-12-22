SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 04/06/13 - Displays errors from Substitute Processing 

EXEC dbo.cvo_substitute_processing_errors_sp	@spid = @@SPID
*/
CREATE PROC [dbo].[cvo_substitute_processing_errors_sp] @spid	INT = @@SPID

AS
BEGIN
	SELECT
		CAST(order_no AS VARCHAR(10)) + '-' + CAST(ext AS VARCHAR(3)) + ' - ' + reason as msg
	FROM
		dbo.cvo_substitute_processing_error (NOLOCK)
	WHERE
		spid = @spid
	ORDER BY
		rec_id
END

GO
GRANT EXECUTE ON  [dbo].[cvo_substitute_processing_errors_sp] TO [public]
GO
