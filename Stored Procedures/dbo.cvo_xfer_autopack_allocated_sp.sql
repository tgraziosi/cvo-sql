SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_xfer_autopack_allocated_sp]	@xfer_no INT
AS
BEGIN
	DECLARE @back_ord_flag	SMALLINT,
			@autopack		SMALLINT,
			@os_qty			DECIMAL(20,8),
			@alloc_qty		DECIMAL(20,8),
			@user_id		VARCHAR(50)

	-- Get transer details
	SELECT
		@back_ord_flag = back_ord_flag,
		@autopack = ISNULL(autopack,0)
	FROM
		dbo.xfers (NOLOCK)
	WHERE
		xfer_no = @xfer_no

	-- If this transfer isn't an auto pack then clear the autopack record if it exists and exit
	IF @autopack = 0
	BEGIN
		DELETE FROM dbo.cvo_autopack_transfer WHERE xfer_no = @xfer_no
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

	-- Get the user name from the current PC client session
	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL   
	BEGIN  
		SELECT @user_id = who FROM #temp_who
	END
	ELSE
	BEGIN
		SELECT @user_id = suser_sname()
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.cvo_autopack_transfer (NOLOCK) WHERE xfer_no = @xfer_no)
	BEGIN
		INSERT dbo.cvo_autopack_transfer(
			xfer_no,
			proc_user_id,
			processed)
		SELECT
			@xfer_no, 
			@user_id,
			0
	END	
END
GO
GRANT EXECUTE ON  [dbo].[cvo_xfer_autopack_allocated_sp] TO [public]
GO
