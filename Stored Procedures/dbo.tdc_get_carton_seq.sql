SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_carton_seq]
	@carton_no	int,
	@seq		int OUTPUT,
	@carton_total	int OUTPUT,
	@unit_total 	int OUTPUT,
	@last_packed  	int OUTPUT 

AS

DECLARE @err 		int,
	@cnt 		int,
	@l_carton   	int,
	@scnt		int,
	@t_carton 	int,
	@t_stat		varchar(255),
	@order_type     char(1),
	@order_no	int,
	@order_ext	int

	----------------------------------------------------------------------------------------------
	-- Initialize the variables
	----------------------------------------------------------------------------------------------
	SELECT @err 	 	= 0
	SELECT @cnt 	 	= 0
	SELECT @t_carton 	= 0
	SELECT @scnt 	 	= 0
	SELECT @t_stat 	 	= ''
	SELECT @seq 		= 0
	SELECT @carton_total 	= 0
	SELECT @unit_total 	= 0
	SELECT @last_packed 	= 0

	---------------------------------------------------------------------------------------------
	-- If there are multiple orders per carton, seq is 0; return 
	---------------------------------------------------------------------------------------------
	IF(SELECT COUNT(carton_no) 
	     FROM tdc_carton_tx (NOLOCK)
	    WHERE carton_no = @carton_no) > 1
	BEGIN
		RETURN 0
	END
	ELSE
	BEGIN
		SELECT @order_no = order_no,
		       @order_ext = order_ext
		  FROM tdc_carton_tx (NOLOCK)
		 WHERE carton_no = @carton_no
	END

	----------------------------------------------------------------------------------------------
	-- Get the order type
	----------------------------------------------------------------------------------------------
	SELECT @order_type = order_type 
	  FROM tdc_carton_tx (NOLOCK) 
	 WHERE carton_no = @carton_no

	------------------------------------------------------------
	-- Get total cartons for the order
	------------------------------------------------------------
	IF (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'carton_total_prompt') = 'Y'
	BEGIN
		SELECT @carton_total = total_cartons
		  FROM tdc_order (NOLOCK)
		 WHERE order_no  = @order_no
		   AND order_ext = @order_ext
	END
	ELSE
	BEGIN
		SELECT @carton_total = COUNT (DISTINCT tdg.parent_serial_no)
		  FROM tdc_dist_group     tdg, 
		       tdc_dist_item_pick tdip
		 WHERE tdip.order_no        = @order_no
		   AND tdip.order_ext       = @order_ext
		   AND tdip.[function] 	    = @order_type
		   AND tdip.child_serial_no = tdg.child_serial_no
	END

	------------------------------------------------------------
	-- Find out how many units are in the specified carton
	------------------------------------------------------------
	SELECT @unit_total = isnull(sum(pack_qty), 0)
	  FROM tdc_carton_detail_tx
	 WHERE carton_no = @carton_no

	------------------------------------------------------------
	-- Find out the sequence of this carton in the order.
	------------------------------------------------------------
	SELECT @cnt = 0
	DECLARE dist_cursor CURSOR FOR 
		SELECT DISTINCT tdg.parent_serial_no
		  FROM tdc_dist_group tdg, tdc_dist_item_pick tdip
		 WHERE tdg.child_serial_no = tdip.child_serial_no
		   AND tdip.order_no = @order_no
		   AND tdip.order_ext = @order_ext
		   AND tdip.[function] = @order_type
		 ORDER BY tdg.parent_serial_no

	OPEN dist_cursor

	FETCH NEXT FROM dist_cursor INTO @t_carton

	WHILE (@@FETCH_STATUS = 0)
	BEGIN	
		SELECT @cnt = @cnt + 1

		------------------------------------------------------------
		-- If carton matches, then return sequence # 
		------------------------------------------------------------
		IF @t_carton = @carton_no SELECT @seq = @cnt

		FETCH NEXT FROM dist_cursor INTO @t_carton
	END

	CLOSE      dist_cursor
	DEALLOCATE dist_cursor

	EXEC @last_packed = tdc_last_carton_sp @order_type, @order_no, @order_ext

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_get_carton_seq] TO [public]
GO
