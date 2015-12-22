SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_calc_carton_seq]
  @carton_no	int

AS

DECLARE @cnt 		int,
	@seq		int,
	@order_no	int,
	@order_ext	int,
	@carton_total	int,
	@order_type	char(1)

 
	---------------------------------------------------------------------------------------------
	-- If there are multiple orders per carton, seq is 0; return 
	---------------------------------------------------------------------------------------------
	IF(SELECT COUNT(carton_no) 
	     FROM tdc_carton_tx (NOLOCK)
	    WHERE carton_no = @carton_no) > 1
	BEGIN
		UPDATE tdc_carton_tx
		   SET carton_seq = 0 
		 WHERE order_no = @order_no 
		   AND order_ext = @order_ext 
		   AND carton_no = @carton_no
		   AND order_type = @order_type
		RETURN 
	END
 
	---------------------------------------------------------------------------------------------
	-- Initialize the variables and get the order, ext, and type
	---------------------------------------------------------------------------------------------
	SELECT @cnt = 0, @seq = 0
	SELECT @order_no = order_no, 
	       @order_ext = order_ext,
	       @order_type = order_type
	   FROM tdc_carton_tx (NOLOCK) 
	  WHERE carton_no = @carton_no

	---------------------------------------------------------------------------------------------
	-- Get the carton total
	---------------------------------------------------------------------------------------------
	IF @order_type = 'S'
		SELECT @carton_total = total_cartons FROM tdc_order (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
	ELSE IF @order_type = 'T'
		SELECT @carton_total = total_cartons FROM tdc_xfers (NOLOCK) WHERE xfer_no = @order_no  
	ELSE 
		RAISERROR('Invalid order type', 16, 1)

	---------------------------------------------------------------------------------------------
	-- If there are multiple orders per carton, return 0
	---------------------------------------------------------------------------------------------
	SELECT @cnt = COUNT(*) 
	  FROM tdc_carton_tx (NOLOCK) 
	 WHERE carton_no in (SELECT DISTINCT a.parent_serial_no 
		 	       FROM tdc_dist_group a (NOLOCK), 
				    tdc_dist_item_pick b (NOLOCK) 
		 	      WHERE a.child_serial_no = b.child_serial_no 
				AND b.order_no = @order_no 
				AND b.order_ext = @order_ext 
				AND b.[function] = @order_type
				AND a.status = 'S')

	---------------------------------------------------------------------------------------------
	-- If the number of cartons is greater than the carton total, update the carton total
	---------------------------------------------------------------------------------------------
	IF (@cnt >= @carton_total)
	BEGIN
		SELECT @carton_total = @carton_total + 1
		IF @order_type = 'S'
		BEGIN			
			UPDATE tdc_order 
			   SET total_cartons = @carton_total 
			 WHERE order_no = @order_no
		END
		ELSE IF @Order_type = 'T'
		BEGIN
			UPDATE tdc_xfers
			   SET total_cartons = @carton_total 
			 WHERE xfer_no = @order_no
		END
	END

	SELECT @seq = @cnt + 1
	UPDATE tdc_carton_tx
	   SET carton_seq = @seq 
	 WHERE order_no = @order_no 
	   AND order_ext = @order_ext 
	   AND carton_no = @carton_no
	   AND order_type = @order_type



RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_calc_carton_seq] TO [public]
GO
