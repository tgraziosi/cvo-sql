SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_xfer_hdr_status]
	@xfer_no integer,
	@msg varchar(100) OUTPUT 
AS

SELECT @msg = ''

DECLARE @language VARCHAR(20)

SELECT @language = @@language -- Get system language

/********************************************************************************************/

/* TDC does not have control to this order	*/
IF NOT EXISTS (SELECT * FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no )
BEGIN
	SELECT @msg = 'Transfer Not found in Supply Chain Execution system'
	RETURN 0
END

IF NOT EXISTS (SELECT * FROM tdc_dist_item_list (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_item_list (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
	BEGIN
		SELECT @msg = 'Transfer Not found in Supply Chain Execution system'
		RETURN 0
	END
END

IF EXISTS (SELECT * FROM xfer_list (nolock) WHERE xfer_no = @xfer_no ANd shipped > 0)
	IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
		IF NOT EXISTS (SELECT * FROM tdc_bkp_dist_item_pick (nolock) WHERE order_no = @xfer_no AND [function] = 'T')
		BEGIN
			SELECT @msg = 'Transfer Not found in Supply Chain Execution system'
			RETURN 0
		END

/* order status is open or void */
IF EXISTS (SELECT * FROM xfers (nolock)	WHERE xfer_no = @xfer_no AND status IN ('O', 'V'))
	RETURN 0

/*****************************************************************************************/

DECLARE @ordered decimal(20,8), @shipped decimal(20,8)
DECLARE @ordered_tot decimal(20,8), @shipped_tot decimal(20,8)
DECLARE @percent int

SELECT @ordered_tot = 0.0, @shipped_tot = 0.0

DECLARE get_qty CURSOR
FOR SELECT ordered, shipped FROM xfer_list WHERE xfer_no = @xfer_no 

OPEN get_qty
FETCH get_qty INTO @ordered, @shipped

WHILE @@FETCH_STATUS = 0
BEGIN
	IF (@shipped > @ordered)
		SELECT @shipped = @ordered

	SELECT @ordered_tot = @ordered_tot + @ordered 
	SELECT @shipped_tot = @shipped_tot + @shipped

	FETCH get_qty INTO @ordered, @shipped
END

CLOSE get_qty
DEALLOCATE get_qty

SELECT @percent = (ROUND(@shipped_tot,0) / ROUND(@ordered_tot,0)) * 100

/* order has been shipped */
IF EXISTS (SELECT * FROM xfers (nolock)	WHERE xfer_no = @xfer_no AND status = 'R')
BEGIN
	SELECT @msg = 'Order has been shipped. Completed: ' + LTRIM(RTRIM(CONVERT(varchar(5), @percent))) + '%.'
	RETURN 0
END

/* order has not been picked */
IF (SELECT SUM(shipped) FROM xfer_list (nolock) WHERE xfer_no = @xfer_no ) = 0
BEGIN
	SELECT @msg = 'Completed: 0%'
	RETURN 0
END

/* order has been received */
IF EXISTS (SELECT * FROM xfers (nolock)	WHERE xfer_no = @xfer_no AND status = 'S')
BEGIN
	SELECT @msg = 'Order has been received. Completed: ' + LTRIM(RTRIM(CONVERT(varchar(5), @percent))) + '%.'
	RETURN 0
END

SELECT @msg = 'Order Currently being Processed. Completed: ' + LTRIM(RTRIM(CONVERT(varchar(5), @percent))) + '%.'

/*********************************************************************************************/

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_xfer_hdr_status] TO [public]
GO
