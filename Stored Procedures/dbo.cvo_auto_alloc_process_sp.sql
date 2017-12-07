SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_auto_alloc_process_sp] @reg int, @process varchar(255) = ''
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- PROCESSING
	IF (@reg = 1)
	BEGIN
		DELETE	cvo_auto_alloc_process
		WHERE	process_id = @@SPID

		INSERT	cvo_auto_alloc_process
		SELECT	@@SPID, @process
	END
	ELSE
	BEGIN
		DELETE	cvo_auto_alloc_process
		WHERE	process_id = @@SPID
	END	

END
GO
GRANT EXECUTE ON  [dbo].[cvo_auto_alloc_process_sp] TO [public]
GO
