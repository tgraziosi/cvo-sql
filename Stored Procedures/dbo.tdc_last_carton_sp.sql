SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------
-- Returns 1 if last carton 0 if not
----------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[tdc_last_carton_sp] (@order_type CHAR(1), @order_no int, @order_ext int)
AS 

DECLARE	@ret	int,
	@line_no		int,
	@pack_qty	decimal(20, 8),
	@pick_qty	decimal(20, 8)


----------------------------------------------------------------------------------------------
-- Initialize the lastcarton return code to 1, which means it is the last
----------------------------------------------------------------------------------------------
SELECT @ret = 1


DECLARE pack_cursor CURSOR FOR 
	SELECT a.line_no, SUM(a.pack_qty)
	FROM tdc_carton_detail_tx a(NOLOCK),
	     tdc_carton_tx b(NOLOCK)
	WHERE a.order_no  = @order_no
	  AND a.order_ext = @order_ext
	  AND a.order_no  = b.order_no
	  AND a.order_ext = b.order_ext
	  AND order_type  = @order_type
GROUP BY a.order_no, a.order_ext, a.line_no

OPEN pack_cursor 

FETCH NEXT FROM pack_cursor INTO @line_no, @pack_qty

WHILE (@@FETCH_STATUS = 0)
BEGIN
	IF @order_type = 'S'
	BEGIN
		SELECT @pick_qty = sum(shipped)
		  FROM ord_list (NOLOCK)
		 WHERE order_no = @order_no
		   AND order_ext = @order_ext
		   AND line_no = @line_no
	END 
	ELSE IF @Order_type = 'T'
	BEGIN
		SELECT @pick_qty = sum(shipped)
		  FROM xfer_list (NOLOCK)
		 WHERE xfer_no = @order_no
		   AND line_no = @line_no
	END

	/* Pack Quantity must match pick quantity in order to be the last carton */
	IF (@pick_qty <> @pack_qty) SELECT @ret = 0
 

	FETCH NEXT FROM pack_cursor INTO @line_no, @pack_qty
END

CLOSE pack_cursor
DEALLOCATE pack_cursor

RETURN @ret
GO
GRANT EXECUTE ON  [dbo].[tdc_last_carton_sp] TO [public]
GO
