SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[cvo_backorder_processing_available_stock_sp] @location		varchar(10),
															@part_no		varchar(30)
AS
BEGIN
	-- Declarations
	DECLARE	@ret_val		decimal(20,8),
			@available		decimal(20,8),
			@soft_alloc		decimal(20,8)

	SET @ret_val = 0

	-- Retrieve the available stock
	EXEC dbo.CVO_AvailabilityInStock_sp @part_no, @location, @available OUTPUT
/*
	-- Get the soft allocted quantity
	SELECT	@soft_alloc = ISNULL(SUM(CASE WHEN deleted = 1 THEN quantity * -1 ELSE quantity END),0) 
	FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
	WHERE	location = @location 
	AND		part_no = @part_no
	AND		status IN (0,1)
*/
	IF (@soft_alloc IS NULL)
		SET @soft_alloc = 0

	SELECT @ret_val = (@available - @soft_alloc)

	-- Return value
	RETURN	@ret_val
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_available_stock_sp] TO [public]
GO
