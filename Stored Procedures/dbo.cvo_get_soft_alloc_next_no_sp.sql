SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_get_soft_alloc_next_no_sp]	
AS
BEGIN
	-- Get the next number for the soft allocation
-- v1.1 BEGIN TRAN
		UPDATE	dbo.cvo_soft_alloc_next_no
		SET		next_no = next_no + 1
-- v1.1 COMMIT TRAN	
	-- Return the number back to the form
	SELECT	next_no
	FROM	dbo.cvo_soft_alloc_next_no

END
GO
GRANT EXECUTE ON  [dbo].[cvo_get_soft_alloc_next_no_sp] TO [public]
GO
