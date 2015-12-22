SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_xfer_autoship_allocated_sp]	@xfer_no INT
AS
BEGIN
	DECLARE @back_ord_flag	SMALLINT,
			@autoship		SMALLINT,
			@os_qty			DECIMAL(20,8),
			@alloc_qty		DECIMAL(20,8)

	-- Get transer details
	SELECT
		@back_ord_flag = back_ord_flag,
		@autoship = ISNULL(autoship,0)
	FROM
		dbo.xfers (NOLOCK)
	WHERE
		xfer_no = @xfer_no

	-- If this transfer isn't an auto ship the exit
	IF @autoship = 0
	BEGIN
		RETURN
	END

	-- If back order status is ship complete then check it is fully allocated
	IF @back_ord_flag = 1
	BEGIN
		-- Get qty o/s
		SELECT
			@os_qty = SUM(ordered - shipped)
		FROM
			dbo.xfer_list (NOLOCK)
		WHERE
			xfer_no = @xfer_no

		-- Get qty allocated
		SELECT
			@alloc_qty = SUM(qty)
		FROM 
			dbo.tdc_soft_alloc_tbl (NOLOCK) 
		WHERE 
			order_type = 'T' 
			AND order_no = @xfer_no
			AND order_ext = 0

		IF ISNULL(@os_qty,0) > ISNULL(@alloc_qty,0)
		BEGIN
			RETURN
		END	
	END

	-- Update auto ship processing record
	UPDATE
		dbo.cvo_autoship_transfer
	SET
		proc_step = 1,
		processed_date = GETDATE()
	WHERE
		xfer_no = @xfer_no
		AND proc_step = 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_xfer_autoship_allocated_sp] TO [public]
GO
