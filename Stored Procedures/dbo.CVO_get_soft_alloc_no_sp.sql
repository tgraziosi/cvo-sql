SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 02/07/2013 - Created

DECLARE @soft_alloc_no INT
EXEC CVO_get_soft_alloc_no_sp 1419732,0, @soft_alloc_no OUTPUT
SELECT @soft_alloc_no

*/
CREATE PROCEDURE [dbo].[CVO_get_soft_alloc_no_sp]	@order_no		INT, 
												@ext			INT,
												@soft_alloc_no	INT OUTPUT
																  
AS
BEGIN
	SET NOCOUNT ON

	-- Check if one already exists
	SELECT	
		@soft_alloc_no = soft_alloc_no 
	FROM		
		dbo.cvo_soft_alloc_hdr (NOLOCK)
	WHERE	
		order_no = @order_no
		AND	order_ext = @ext
		AND	[status] IN (0, 1, -3, -4) 

	-- If it doesn't exist then get a new one
	IF ISNULL(@soft_alloc_no,0) = 0
	BEGIN
		CREATE TABLE #soft_alloc_no(
			soft_alloc_no INT)

		INSERT INTO #soft_alloc_no EXEC dbo.cvo_get_soft_alloc_next_no_sp

		SELECT 
			@soft_alloc_no = soft_alloc_no 
		FROM
			#soft_alloc_no
	END
END

GO
GRANT EXECUTE ON  [dbo].[CVO_get_soft_alloc_no_sp] TO [public]
GO
