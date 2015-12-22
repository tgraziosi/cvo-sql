SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_upd_ord_tots]
	@order_no	int,
	@order_ext	int
AS

	--Update orders table   
	IF (SELECT freight_allow_type
	      FROM orders(NOLOCK) 
	     WHERE order_no = @order_no
	       AND ext      = @order_ext) = '8' -- <>'8'  -- DMoon 2/2/1012 never update freight to clippership pub freight
	BEGIN
	--	UPDATE orders 
	--	   SET freight  = ISNULL((SELECT SUM(cs_published_freight)
	--				   FROM tdc_carton_tx (NOLOCK)  
	--	                          WHERE order_no  = @order_no 
	--	                            AND order_ext = @order_ext),0)
	--	 WHERE order_no = @order_no
	--          AND ext      = @order_ext
	
		EXEC fs_updordtots @order_no, @order_ext
	END
GO
GRANT EXECUTE ON  [dbo].[tdc_upd_ord_tots] TO [public]
GO
