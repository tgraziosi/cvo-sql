SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[cvo_backorder_processing_available_stock_sp] @location		varchar(10),
															@part_no		varchar(30),
															@rx_reserve		int = 0 -- v1.1
AS
BEGIN
	-- Declarations
	DECLARE	@ret_val		decimal(20,8),
			@available		decimal(20,8),
			@soft_alloc		decimal(20,8),
			@allocated		decimal(20,8) -- v1.1

	SET @ret_val = 0

	-- v1.1 Start
	IF (@rx_reserve = 1)
	BEGIN
		SET @available = NULL

		SELECT	@available = SUM(qty)
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no
		AND		b.group_code = 'RESERVE'

		IF (@available IS NULL)
			SET @available = 0

		SET @allocated = NULL

		SELECT	@allocated = SUM(qty)
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no
		AND		b.group_code = 'RESERVE'
		
		IF (@allocated IS NULL)
			SET @allocated = 0

		SET @ret_val = @available - @allocated

		RETURN	@ret_val
	END
	-- v1.1 End

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
