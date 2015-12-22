SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_dist_get_item_orders] AS
/********************************************************************
 *
 * 980623 REA
 *	Procedure break-out from original tdc_dist_ship_pkg.
 *	This proc can be used by the ASN process as well.
 */
set nocount on

/*
 * Tables used internally
 */

/*
 * Declare/Initialize error code(s)
 */
DECLARE @err_no_orders int
SELECT	@err_no_orders = -101

DECLARE @return_code int
SELECT @return_code = 0

TRUNCATE TABLE #order_list_out


IF EXISTS (SELECT * from #int_list_in) BEGIN
	INSERT INTO #order_list_out (order_no, order_ext)
		SELECT DISTINCT p.order_no, p.order_ext
			FROM tdc_dist_item_pick p, #int_list_in i
			WHERE (p.child_serial_no = i.serial_no)
	/*
	 * It is assumed that an existing list of items should
	 * produce at least one order/ext
	 */
	IF NOT EXISTS (SELECT * from #order_list_out) BEGIN
		SELECT @return_code = @err_no_orders
		INSERT INTO #err_list_out (err_no, err_msg)
			VALUES (@err_no_orders, 'No orders were found')
		END
	END

RETURN @return_code

GO
GRANT EXECUTE ON  [dbo].[tdc_dist_get_item_orders] TO [public]
GO
